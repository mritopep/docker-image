#imports
import requests
import zipfile
import os

#library files
from get_link import get_files


curr_path = str(os.path.dirname(os.path.abspath(__file__))).replace("/scripts/dataset_script","/raw_data")

# file locations
DOWNLOAD=f'{curr_path}/DOWNLOADED/'
ADNI=f'{curr_path}/DATA/ADNI/'
CANCER=f'{curr_path}/DATA/CANCER/'
EXTRACT=f'{curr_path}/EXTRACT/'


def download_file_from_google_drive(id, destination):
    URL = "https://docs.google.com/uc?export=download"
    session = requests.Session()
    response = session.get(URL, params = { 'id' : id }, stream = True)
    token = get_confirm_token(response)
    if token:
        params = { 'id' : id, 'confirm' : token }
        response = session.get(URL, params = params, stream = True)
    save_response_content(response, destination)    

def get_confirm_token(response):
    for key, value in response.cookies.items():
        if key.startswith('download_warning'):
            return value
    return None

def save_response_content(response, destination):
    CHUNK_SIZE = 32768
    with open(destination, "wb") as f:
        for chunk in response.iter_content(CHUNK_SIZE):
            if chunk: # filter out keep-alive new chunks
                f.write(chunk)


def extract(source,destination):
    with zipfile.ZipFile(source, 'r') as zip_ref:
        files = zip_ref.infolist()
        for file in files:
            try:
                zip_ref.extract(file,path=destination)
            except:
                print(file.filename+"\n")

def make_dir():
    try:
        os.makedirs(DOWNLOAD)
        os.makedirs(EXTRACT)
        os.makedirs(ADNI)
        os.makedirs(CANCER)    
    except:
        pass

def download_data():
    downloaded_files=[]
    files=get_files()
    files=files[:1]
    for fs in files:
        file_id=fs['id']
        file_path=DOWNLOAD+fs['name']
        file_name=fs['name']
        download_file_from_google_drive(file_id, file_path)
        downloaded_files.append({"name":file_name,"path":file_path})
        print(f'name:{file_name} path: {file_path}')
    return downloaded_files

def extract_files(downloaded_files):
    extract_paths=[]
    for fs in downloaded_files:
      extract_path=EXTRACT+fs['name'][:-4]
      extract(fs['path'],extract_path)
      print(f'name:{fs["name"]} path: {extract_path}')
      os.remove(fs['path'])
      extract_paths.append(extract_path)
    return extract_paths

def get_nii_files(extracted_paths):
    nii_files=[]
    for extract_path in extracted_paths:
      for r, d, f in os.walk(extract_path):
          for file in f:
              if file.endswith(".nii"):
                file_name=file
                file_path=os.path.join(r, file)
                nii_files.append({"name":file_name,"path":file_path})
                print(f'name:{file_name} path: {file_path}')
    return nii_files

def get_data():
    make_dir()
    downloaded_files=download_data()
    extracted_paths=extract_files(downloaded_files)
    nii_files=get_nii_files(extracted_paths)
    return nii_files

def main():
    print(curr_path)
    # print(get_data())


if __name__ == "__main__":
    main()