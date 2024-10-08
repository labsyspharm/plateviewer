#!/usr/bin/env python

import argparse
import concurrent.futures
import multiprocessing
import numpy as np
import os
import scipy.stats
import sklearn.mixture
import sys
import threadpoolctl
import tifffile
import time


def auto_threshold(img):

    assert img.ndim == 2

    yi, xi = np.floor(np.linspace(0, img.shape, 200, endpoint=False)).astype(int).T
    # Slice one dimension at a time. Should generally use less memory than a meshgrid.
    img = img[yi]
    img = img[:, xi]
    img_log = np.log(img[img > 0])
    if len(np.unique(img_log)) < 2:
        return img.min(), img.max()

    gmm = sklearn.mixture.GaussianMixture(3, max_iter=1000, tol=1e-6)
    gmm.fit(img_log.reshape((-1,1)))
    means = gmm.means_[:, 0]
    _, i1, i2 = np.argsort(means)
    mean1, mean2 = means[[i1, i2]]
    std1, std2 = gmm.covariances_[[i1, i2], 0, 0] ** 0.5

    x = np.linspace(mean1, mean2, 50)
    y1 = scipy.stats.norm(mean1, std1).pdf(x) * gmm.weights_[i1]
    y2 = scipy.stats.norm(mean2, std2).pdf(x) * gmm.weights_[i2]

    lmax = mean2 + 2 * std2
    lmin = x[np.argmin(np.abs(y1 - y2))]
    if lmin >= mean2:
        lmin = mean2 - 2 * std2
    vmin = max(np.exp(lmin), img.min(), 0)
    vmax = min(np.exp(lmax), img.max())

    return vmin, vmax


def progress(it, total, interval=10):

    def log(i):
        timestamp = time.strftime('%Y-%m-%d %H:%M:%S')
        percentage = round(i / total * 100)
        print(f'{timestamp} progress: {percentage}% ({i} / {total})', flush=True)

    log(0)
    last_log = time.time()
    last_i = 0
    for i, item in enumerate(it, 1):
        now = time.time()
        if now >= last_log + interval or (i == total and last_i < i):
            log(i)
            last_log = now
            last_i = i
        yield item
    print('Done!', flush=True)


parser = argparse.ArgumentParser()
parser.add_argument('-i', '--input', required=True, nargs='+', help='Input tif paths')
parser.add_argument('-o', '--output', required=True, help='Output .csv file containing min/max intensities')
parser.add_argument('-c', '--csv', help='Output .csv file containing full intensities table')
parser.add_argument('-j', '--jobs', default=0, type=int, help='Number of jobs to run simultaneously (default: number of available CPUs)')
args = parser.parse_args()

def process(p):
    img = tifffile.imread(p)
    vmin, vmax = auto_threshold(img)
    return vmin, vmax

if args.jobs == 0:
    if hasattr(os, 'sched_getaffinity'):
        args.jobs = len(os.sched_getaffinity(0))
    else:
        args.jobs = multiprocessing.cpu_count()
print(f"Worker threads: {args.jobs}")

threadpoolctl.threadpool_limits(1)

pool = concurrent.futures.ThreadPoolExecutor(max_workers=args.jobs)
futures = [pool.submit(process, p) for p in args.input]
it = concurrent.futures.as_completed(futures)
intensities = [f.result() for f in progress(it, len(futures))]

vmin, vmax = np.median(intensities, axis=0).round().astype(int)
with open(args.output, 'w') as f:
    f.write('Vmin,Vmax\n')
    f.write(f'{vmin},{vmax}\n')

if args.csv:
    with open(args.csv, 'w') as f:
        f.write('Vmin,Vmax\n')
        for row in intensities:
            f.write(','.join(str(r) for r in row))
            f.write('\n')
