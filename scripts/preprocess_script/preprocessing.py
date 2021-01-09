import os

curr_path = str(os.path.dirname(os.path.abspath(__file__))).replace("/scripts/preprocess_script","/raw_data/DATA")

preprocessed_data=str(os.path.dirname(os.path.abspath(__file__))).replace("/scripts/preprocess_script","/preprocesed_data/DATA")

def image_registration(pet_image,mri_image):
    os.system(f"python image_registation {pet_image} {mri_image}")

def intensity_normalization():
    pass

def skull_strip():
    pass

def bias_correction():
    pass

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