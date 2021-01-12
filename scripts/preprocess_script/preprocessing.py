import os
import xml.etree.ElementTree as ET
from datetime import date
from shutil import copyfile
import shutil

curr_path = str(os.path.dirname(os.path.abspath(__file__))).replace("/scripts/preprocess_script","/raw_data")

preprocessed_data=str(os.path.dirname(os.path.abspath(__file__))).replace("/scripts/preprocess_script","/preprocesed_data")

# file locations
DOWNLOAD=f'{curr_path}/DOWNLOADED/'
ADNI=f'{curr_path}/DATA/ADNI/'
CANCER=f'{curr_path}/DATA/CANCER/'
EXTRACT=f'{curr_path}/EXTRACT/'
METADATA_ADNI=f'{curr_path}/METADATA/ADNI/'
METADATA_CANCER=f'{curr_path}/METADATA/CANCER/'
METADATA=f'{curr_path}/METADATA/'
temp_intensity_input=f'{curr_path}/TEMP/intensity_normalization/input'
temp_intensity_output=f'{curr_path}/TEMP/intensity_normalization/output'
temp_skull_output=f'{curr_path}/TEMP/skull_strip/output'

def make_dir():
    print("\nMAKING DIR\n")
    try:
        os.makedirs(DOWNLOAD)
        os.makedirs(EXTRACT)
        os.makedirs(ADNI)
        os.makedirs(CANCER)  
        os.makedirs(METADATA_ADNI)  
        os.makedirs(METADATA_CANCER)
        os.makedirs(METADATA)
        os.makedirs(temp_intensity_input)
        os.makedirs(temp_intensity_output)
        os.makedirs(temp_skull_output)
        os.makedirs(preprocessed_data)
    except:
        pass

def remove_dir():
    print("\nREMOVE DIR\n")
    try:
        os.removedirs(temp_intensity_input)
        os.removedirs(temp_intensity_output)
        os.removedirs(temp_skull_output)
    except:
        pass

def image_registration(pet_image,mri_image):
    os.system(f"image_reg.py {mri_image} {pet_image}")

def intensity_normalization(input_image,output_image):
    os.system(f"fcm-normalize -i {temp_intensity_input}  -o {temp_intensity_output}")

def skull_strip(input_image,output_image):
    os.system(f"skull_strip.py -i {input_image} -o output {temp_skull_output}")

def bias_correction(input_image,output_image):
    os.system(f"bais_field_correction.py {input_image} {output_image}")

def petpvc(input_image,output_image):
    os.system(f"petpvc -i {input_image} -o {output_image}")

def get_folder_names(path):
    return os.listdir(path)

def get_metadata(dataset):
    xml_files={}
    for r, d, f in os.walk(METADATA_ADNI):
          for file in f:
              if file.endswith(".xml") and file.startswith("ADNI"):
                file_path=os.path.join(r, file)
                subId,seriesId,imageId,date = get_xml_data(file_path)
                id=f"S{seriesId}_I{imageId}"
                xml_files[id]={"subId":subId,"date":date}
    return xml_files

def get_xml_data(path):
    tree = ET.parse(path)
    root = tree.getroot()
    subId=root.find("./project/subject/subjectIdentifier").text
    seriesId=root.find("./project/subject/study/series/seriesIdentifier").text
    imageId=root.find("./project/subject/study/imagingProtocol/imageUID").text
    date=root.find("./project/subject/study/series/dateAcquired").text
    return [subId,seriesId,imageId,date]

metadata=get_metadata("ADNI")

def get_name(scan_path):
    if(scan_path.find("/PT/")!=-1):
        index=scan_path.find("/PT/")
    index=scan_path.find("/MR/")
    return scan_path[index+4:-4]+".xml"

def get_date(scan_path):
    name=get_name(scan_path)
    for k in metadata.keys():
        if(k in name):
            if(metadata[k]["subId"] in name):
                return metadata[k]["date"]

def get_diff(mri_date,pet_date):
    year,month,day=[int(i) for i in mri_date.split("-")]
    d0 = date(year,month,day)
    year,month,day=[int(i) for i in pet_date.split("-")]
    d1 = date(year,month,day)
    diff = d1 - d0
    return diff.days

def pair_scan_images(MR,PT):
    pair_data=[]

    if(len(MR)==1 or len(PT)==1):
        for mri in MR:
            for pet in PT:
                pair_data.append({"mr":mri,"pt":pet})
        return pair_data

    for mri in MR:
        min_diff=float('inf')
        cache_data={}
        for pet in PT:
            mri_date=get_date(mri)
            pet_date=get_date(pet)
            diff=get_diff(mri_date,pet_date)
            if(diff not in cache_data.keys()):
                cache_data[diff]={"mr":mri,"pt":pet}
            if(diff<min_diff):
                min_diff=diff
        pair_data.append(cache_data[int(min_diff)])

    for pet in PT:
        min_diff=float('inf')
        cache_data={}
        for mri in MR:
            mri_date=get_date(mri)
            pet_date=get_date(pet)
            diff=get_diff(mri_date,pet_date)
            if(diff not in cache_data.keys()):
                cache_data[diff]={"mr":mri,"pt":pet}
            if(diff<min_diff):
                min_diff=diff
        pair_data.append(cache_data[int(min_diff)])

    res = [] 
    for i in pair_data: 
        if i not in res: 
            res.append(i) 
    
    print(len(res),len(pair_data))
    return res

def preprocess_lock():
    return ["002_S_4213"]

def preprocess():
    make_dir()
    subject_ids=get_folder_names(ADNI)
    subject_ids=preprocess_lock()
    MR=[]
    PT=[]
    paired_data=[]
    for id in subject_ids:

        files = os.listdir(f"{ADNI}{id}/MR")
        for file in files:
            MR.append(f"{ADNI}{id}/MR/{file}")

        files = os.listdir(f"{ADNI}{id}/PT")
        for file in files:
            PT.append(f"{ADNI}{id}/PT/{file}")

        paired_data+=pair_scan_images(MR,PT)

    for item in paired_data:
        print(item)
    
    remove_dir()

if __name__ == "__main__":
    preprocess()