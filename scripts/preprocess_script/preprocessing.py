import os

curr_path = str(os.path.dirname(os.path.abspath(__file__))).replace("/scripts/preprocess_script","/raw_data/DATA")

preprocessed_data=str(os.path.dirname(os.path.abspath(__file__))).replace("/scripts/preprocess_script","/preprocesed_data/DATA")

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





def main():
    preprocess()


if __name__ == "__main__":
    main()