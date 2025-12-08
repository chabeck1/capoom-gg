#!/usr/bin/env python3
"""
Simple PLY segmentation tools.
Supports three modes:
  - obj_dc: use precomputed object descriptors in properties named "obj_dc_0", "obj_dc_1", ...
            (argmax over descriptors -> per-point label)
  - color_kmeans: cluster by RGB colors using KMeans
  - dbscan: spatial clustering (DBSCAN) using XYZ coordinates

Writes a new PLY with an added property `label` (int).

Dependencies: plyfile, numpy, scikit-learn (for KMeans/DBSCAN)
Install: pip install plyfile numpy scikit-learn

Examples:
  # Label from obj_dc fields
  python tools/segment_ply.py --input output/mcity_100k/point_cloud/iteration_100000/point_cloud.ply --mode obj_dc --output pc_labeled.ply

  # Color clustering
  python tools/segment_ply.py --input input.ply --mode color_kmeans --n-clusters 8 --output pc_color_k8.ply

  # Spatial DBSCAN
  python tools/segment_ply.py --input input.ply --mode dbscan --eps 0.2 --min-samples 10 --output pc_dbscan.ply

"""
import argparse
import sys
import numpy as np

try:
    from plyfile import PlyData, PlyElement
except Exception as e:
    print("Error: plyfile is required. Install with: pip install plyfile")
    raise


def read_ply(path):
    ply = PlyData.read(path)
    vertex = ply['vertex']
    names = vertex.data.dtype.names
    data = {n: vertex[n] for n in names}
    return data, names, ply


def write_ply_with_label(path, original_ply, labels, label_name='label'):
    vertex = original_ply['vertex']
    names = vertex.data.dtype.names
    # Build structured array with existing properties plus label
    orig_arr = vertex.data
    n = len(orig_arr)
    
    # Generate distinct colors for each cluster
    unique_labels = np.unique(labels[labels >= 0])  # Exclude -1 (noise in DBSCAN)
    num_clusters = len(unique_labels)
    print(f"Found {num_clusters} clusters")
    
    # Create color palette using HSV
    import colorsys
    colors = np.zeros((num_clusters + 1, 3))  # +1 for noise label -1
    for i in range(num_clusters):
        hue = i / max(num_clusters, 1)
        rgb = colorsys.hsv_to_rgb(hue, 0.9, 0.9)
        colors[i] = rgb
    colors[-1] = [0.5, 0.5, 0.5]  # Gray for noise
    
    # Map labels to colors
    label_to_idx = {lbl: i for i, lbl in enumerate(unique_labels)}
    label_to_idx[-1] = num_clusters  # Noise points
    
    cluster_colors = np.array([colors[label_to_idx[lbl]] for lbl in labels])
    
    # Create new dtype - replace f_dc with colors
    new_dtype = []
    for name, dtype_str in orig_arr.dtype.descr:
        if name in ['f_dc_0', 'f_dc_1', 'f_dc_2']:
            continue  # Skip SH coefficients, we'll add RGB
        new_dtype.append((name, dtype_str))
    
    # Add RGB colors and label
    new_dtype += [('f_dc_0', 'f4'), ('f_dc_1', 'f4'), ('f_dc_2', 'f4'), (label_name, 'i4')]
    
    new_arr = np.empty(n, dtype=new_dtype)
    for name in names:
        if name not in ['f_dc_0', 'f_dc_1', 'f_dc_2']:
            new_arr[name] = orig_arr[name]
    
    # Set cluster colors (RGB in SH DC0 encoding)
    new_arr['f_dc_0'] = (cluster_colors[:, 0] - 0.5) / 0.28209479177387814
    new_arr['f_dc_1'] = (cluster_colors[:, 1] - 0.5) / 0.28209479177387814
    new_arr['f_dc_2'] = (cluster_colors[:, 2] - 0.5) / 0.28209479177387814
    new_arr[label_name] = labels.astype(np.int32)
    
    el = PlyElement.describe(new_arr, 'vertex')
    PlyData([el], text=False).write(path)
    print(f"Wrote labeled PLY with cluster colors to {path} (n={n})")


def mode_obj_dc(data, names):
    # find properties starting with obj_dc_
    obj_keys = [n for n in names if n.startswith('obj_dc_')]
    if not obj_keys:
        raise ValueError('No obj_dc_* properties found in PLY')
    arr = np.stack([data[k] for k in obj_keys], axis=1)
    # If values small or unnormalized, softmax isn't necessary for argmax
    labels = np.argmax(arr, axis=1)
    return labels


def mode_color_kmeans(data, names, n_clusters=8):
    # try to find color properties: RGB or SH DC terms (f_dc_0,1,2)
    color_keys = None
    for kset in (('red','green','blue'), ('r','g','b'), ('red_f','green_f','blue_f'), ('f_dc_0','f_dc_1','f_dc_2')):
        if all(k in names for k in kset):
            color_keys = kset
            break
    if color_keys is None:
        raise ValueError('No RGB or f_dc properties found in PLY (expected red/green/blue or f_dc_0/f_dc_1/f_dc_2)')
    colors = np.stack([data[k] for k in color_keys], axis=1).astype(np.float32)
    # normalize if needed (for RGB, assume 0-255)
    if colors.max() > 1.5 and 'f_dc' not in color_keys[0]:
        colors = colors / 255.0
    try:
        from sklearn.cluster import KMeans
    except Exception:
        raise RuntimeError('scikit-learn required for color_kmeans: pip install scikit-learn')
    km = KMeans(n_clusters=n_clusters, random_state=0)
    labels = km.fit_predict(colors)
    return labels


def mode_dbscan(data, names, eps=0.1, min_samples=10):
    for kset in (('x','y','z'), ('X','Y','Z')):
        if all(k in names for k in kset):
            xyz_keys = kset
            break
    if not any(k in names for k in ('x','y','z','X','Y','Z')):
        raise ValueError('No XYZ properties found in PLY')
    xyz = np.stack([data[k] for k in xyz_keys], axis=1).astype(np.float32)
    try:
        from sklearn.cluster import DBSCAN
    except Exception:
        raise RuntimeError('scikit-learn required for dbscan: pip install scikit-learn')
    db = DBSCAN(eps=eps, min_samples=min_samples)
    labels = db.fit_predict(xyz)
    return labels


def main():
    p = argparse.ArgumentParser()
    p.add_argument('--input', '-i', required=True)
    p.add_argument('--mode', '-m', required=True, choices=['obj_dc', 'color_kmeans', 'dbscan'])
    p.add_argument('--output', '-o', required=True)
    p.add_argument('--n-clusters', type=int, default=8)
    p.add_argument('--eps', type=float, default=0.2)
    p.add_argument('--min-samples', type=int, default=10)
    p.add_argument('--subsample', type=int, default=None, help='Subsample to N points for faster clustering')
    args = p.parse_args()

    data, names, ply = read_ply(args.input)
    print(f"Read PLY: {args.input} with properties: {names}")

    if args.mode == 'obj_dc':
        labels = mode_obj_dc(data, names)
    elif args.mode == 'color_kmeans':
        labels = mode_color_kmeans(data, names, n_clusters=args.n_clusters)
    elif args.mode == 'dbscan':
        labels = mode_dbscan(data, names, eps=args.eps, min_samples=args.min_samples)
    else:
        raise RuntimeError('Unknown mode')

    write_ply_with_label(args.output, ply, labels)

if __name__ == '__main__':
    main()
