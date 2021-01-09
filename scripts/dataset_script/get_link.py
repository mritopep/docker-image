import pickle
import os.path
from googleapiclient.discovery import build
from google_auth_oauthlib.flow import InstalledAppFlow
from google.auth.transport.requests import Request

# If modifying these scopes, delete the file token.pickle.
SCOPES = ['https://www.googleapis.com/auth/drive.metadata.readonly']

tokens = ["tokens/acc1_token.pickle","tokens/acc2_token.pickle","tokens/acc3_token.pickle"]

creds = None

curr_path = os.path.dirname(os.path.abspath(__file__))

def login(creds):
    # let the user log in.
    if not creds or not creds.valid:
        if creds and creds.expired and creds.refresh_token:
            creds.refresh(Request())
        else:
            flow = InstalledAppFlow.from_client_secrets_file(
                f'{curr_path}/credentials.json', SCOPES)
            creds = flow.run_local_server(port=0)
        # Save the credentials for the next run
        with open(f'{curr_path}/token.pickle', 'wb') as token:
            pickle.dump(creds, token)

def load_cred(name):
    if os.path.exists(f'{curr_path}/{name}'):
        with open(f'{curr_path}/{name}', 'rb') as token:
            creds = pickle.load(token)
            return creds
    else:
        print("token not found")

def get_id(creds):
    files = []
    service = build('drive', 'v3', credentials=creds)
    results = service.files().list(fields="nextPageToken, files(id, name)").execute()
    items = results.get('files', [])
    if items:
        for item in items:
            if(item['name'].find(".zip")!=-1):
                if(item['name'].find("metadata")==-1):
                    print(u'{0} ({1})'.format(item['name'], item['id']))
                    files.append(item)
    else:
        print("no files found")
    return files

def get_files():
    files=[]
    for token in tokens:
        creds=load_cred(token)
        files.extend(get_id(creds))
    return files
    
def main():
    print(curr_path)
    print(get_files())
    
    
if __name__ == '__main__':
    main()