#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Filename: common.py
Description: 一些共同的函数和常量
Author: [TangPing.co]
Date: [2024-09-15]
Version: [V0.1]
Dependencies: [T.B.D]
"""

import os
import sys
import subprocess
import argparse


def realpath(f):
    """
    返回文件或目录的绝对路径。

    参数:
        f (str): 文件或目录的路径。

    返回:
        str: 文件或目录的绝对路径。

    """

    if os.path.isdir(f):
        base = ""
        dir = f
    else:
        base = "/" + os.path.basename(f)
        dir = os.path.dirname(f)
    dir = os.path.abspath(dir)
    return dir + base
    if os.path.isdir(f):
        base = ""
        dir = f
    else:
        base = "/" + os.path.basename(f)
        dir = os.path.dirname(f)
    dir = os.path.abspath(dir)
    return dir + base