import os
import shutil
from shutil import copyfile
from os import path
from os import listdir
from os.path import isfile, join

#library
from set_data import download_data,extract_files

curr_path = str(os.path.dirname(os.path.abspath(__file__))).replace("/scripts/dataset_script","/raw_data")

# file locations
DOWNLOAD=f'{curr_path}/DOWNLOADED/'
METADATA_ADNI=f'{curr_path}/METADATA/ADNI/'
METADATA_CANCER=f'{curr_path}/METADATA/CANCER/'
EXTRACT=f'{curr_path}/EXTRACT/'

def make_dir():
    print("\nMAKING DIR\n")
    try:
        os.makedirs(DOWNLOAD)
        os.makedirs(EXTRACT)
        os.makedirs(METADATA_ADNI)  
        os.makedirs(METADATA_CANCER)     
    except:
        pass

def get_xml_files(extracted_paths):
    xml_files=[]
    for extract_path in extracted_paths:
        files = [f for f in listdir(extract_path) if isfile(join(extract_path, f))]
        print(files)
        for file in files:
            if file.endswith(".xml"):
                file_name=file
                file_path=os.path.join(extract_path, file)
                xml_files.append({"name":file_name,"path":file_path})
                print(f'name:{file_name} path: {file_path}')
    print("\nGOT XML FILE\n")
    return xml_files

def copy_metadata(files):
    for file in files:
        copyfile(file["path"], METADATA_ADNI+file["name"])
    shutil.rmtree(EXTRACT) 

def get_metadata():
    make_dir()
    downloaded_files=download_data("adni_metadata")
    extracted_files=extract_files(downloaded_files)
    xml_files=get_xml_files(extracted_files)
    copy_metadata(xml_files)












if __name__ == "__main__":
    get_metadata()
    


























