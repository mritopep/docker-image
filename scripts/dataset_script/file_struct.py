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

def get_id_and_mod(name):
  #ADNI DATASET
  mod=""
  if(name.find('_P') !=-1):
    mod="PT"
    id_index=name.find('_P') 
  if(name.find('_M') !=-1):
    mod="MR"
    id_index=name.find('_M')
  sub_id=name[5:id_index]
  return [sub_id,mod]

def make_dir(file_data):
  sub_id,mod=get_id_and_mod(file_data["name"])
  loc=ADNI+sub_id+"/"+mod
  if(path.isdir(loc)==False):
    try:  
      os.makedirs(loc) 
    except OSError as error:  
        print(error) 
  copyfile(file_data["path"], loc+"/"+file_data["name"])
  print(f"file copied :{loc}/{file_data['name']}")

def make_struct():
    files=get_data()
    for f in files:
        make_dir(f)
    shutil.rmtree(EXTRACT) 

def main():
    print(curr_path)
    make_struct()

if __name__ == "__main__":
    main()