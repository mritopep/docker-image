import os
import shutil
from shutil import copyfile
from os import path

#library
from set_data import get_data

curr_path = str(os.path.dirname(os.path.abspath(__file__))).replace("/scripts/dataset_script","/raw_data")

# file locations
DOWNLOAD=f'{curr_path}/DOWNLOADED/'
ADNI=f'{curr_path}/DATA/ADNI/'
CANCER=f'{curr_path}/DATA/CANCER/'
EXTRACT=f'{curr_path}/EXTRACT/'




































