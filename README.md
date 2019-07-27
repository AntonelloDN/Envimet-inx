# Envimet-inx
A basic plugin for Sketchup to write *.inx files of ENVI_MET 4.3.

## Features:
- Calculate automatically grid dimensions based on buildings
- Create a 3d model with buildings, 2d trees
- Ricalculate buildings or 2d trees

## Limits:
- Unit of the template must be "meter"
- Components and Group not supported
- Buildings must be volumes
- You can apply only one wall material and roof material for all buildings or context
- You cannot manage soils and dem
- This plugin is a beta release

## Setup:
Install *rbz from Sketchup Extension Warehouse.

## To do:
a) A better method to create voxels... performance issue if model is huge.<br>
b) Study a way to apply materials<br>
c) Dem modeling<br>
d) Soil modeling<br>
e) Improve location settings. E.g. a way to set timezone.<br>
f) Improve exception handling<br>
g) Manage Components and Groups<br>
