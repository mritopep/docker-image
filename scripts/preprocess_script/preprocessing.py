import os
import sys 


curr_path = str(os.path.dirname(os.path.abspath(__file__))).replace("/scripts/preprocess_script","/raw_data/DATA")

preprocessed_data=str(os.path.dirname(os.path.abspath(__file__))).replace("/scripts/preprocess_script","/preprocesed_data/DATA")

# file locations
DOWNLOAD=f'{curr_path}/DOWNLOADED/'
ADNI=f'{curr_path}/DATA/ADNI/'
CANCER=f'{curr_path}/DATA/CANCER/'
EXTRACT=f'{curr_path}/EXTRACT/'
METADATA_ADNI=f'{curr_path}/METADATA/ADNI/'
METADATA_CANCER=f'{curr_path}/METADATA/CANCER/'
METADATA=f'{curr_path}/METADATA/'

def image_registration(pet_image,mri_image):
    os.system(f"image_reg.py {mri_image} {pet_image}")

def intensity_normalization(input_dir,output_dir):
    os.system(f"fcm-normalize -i {input_dir}  -o {output_dir}")

def skull_strip(input_image,output_dir):
    os.system(f"skull_strip.py -i {input_image} -o output {output_dir}")

def bias_correction(input_image,output_image):
    os.system(f"bais_field_correction.py {input_image} {output_image}")

def petpvc(input_image,output_image):
    os.system(f"petpvc -i {input_image} -o {output_image}")

def get_folder_names(dataset):
    return os.listdir(f"{curr_path}/{dataset}/")

def get_metadata(dataset):
    xml_files=[]
    for r, d, f in os.walk(METADATA+dataset+"/"):
          for file in f:
              if file.endswith(".xml") and file.startswith("ADNI"):
                file_name=file
                file_path=os.path.join(r, file)
                xml_files.append({"name":file_name,"path":file_path})
                print(f'name:{file_name} path: {file_path}')
    print("\nGOT XML FILE\n")
    return xml_files


def pair_scan_images(MR,PT):
    pair_data=[]
    metadata_files=get_metadata("ADNI")
    for mri in MR:
        min_diff=sys.maxint
        cache_data={}
        for pet in PT:
            mri_date=get_date(mri)
            pet_date=get_date(pet)
            diff=get_diff(mri_date,pet_date)
            if(diff not in cache_data.keys()):
                cache_data[diff]={"mr":mri,"pt":pet}
            if(diff<min_diff):
                min_diff=diff
        pair_data.append(cache_data[min_diff])
    return pair_data

def preprocess():
    DATASET="ADNI"
    os.system(f"mkdir {preprocessed_data}/{DATASET}")
    subject_ids=get_folder_names(DATASET)
    subject_ids=subject_ids[3:4]
    MR=[]
    PT=[]
    for id in subject_ids:
        files = os.listdir(f"{curr_path}/{DATASET}/{id}/MR")
        for file in files:
            MR.append(f"{curr_path}/{DATASET}/{id}/MR/{file}")
        files = os.listdir(f"{curr_path}/{DATASET}/{id}/PT")
        for file in files:
            PT.append(f"{curr_path}/{DATASET}/{id}/PT/{file}")
        print(MR,PT)
        pair_scan_images(MR,PT)





def main():
    preprocess()


if __name__ == "__main__":
    main()