#!/usr/bin/python

'''
A quick python script to automate curl->googledrive interfacing
This should require nothing more than the system python version and curl. Written for python2.7 (with 3 in mind).

Modified from code by: Dan Ellis 2020
'''
import os,sys,json,time
import google_keys * # py file defining 'client_id' and 'client_secret', do not version control!

startTime = time.time()

if sys.version[0]=='3':
  raw_input = lambda(x): input(x)
  
##############################
#Owner information goes here!#
##############################
name = '2017MergeCDLLANDFIRE'

##############################
# zip files (or do this before running this script)
#cmd3 = os.popen('tar cvf %s.tar %s'%(name,' '.join(sys.argv[1:]))).read
#print(cmd3)

cmd1 = json.loads(os.popen('curl -d "client_id=%s&scope=https://www.googleapis.com/auth/drive.file"\
 https://oauth2.googleapis.com/device/code'%client_id).read())

str(raw_input('\n Enter %(user_code)s\n\n at %(verification_url)s \n\n Then hit Enter to continue.'%cmd1))

str(raw_input('(twice)'))

cmd2 = json.loads(os.popen( ('curl -d client_id=%s -d client_secret=%s -d device_code=%s\
 -d grant_type=urn~~3Aietf~~3Aparams~~3Aoauth~~3Agrant-type~~3Adevice_code https://accounts.google.com/o/oauth2/token'\
 %( client_id, client_secret, cmd1['device_code'] ) ).replace('~~','%')).read())
print(cmd2)


cmd4 = os.popen('''
curl -X POST -L \
    -H "Authorization: Bearer %s" \
    -F "metadata={name :\'%s\'};type=application/json;charset=UTF-8" \
    -F "file=@%s.tar;type=application/tar" \
    "https://www.googleapis.com/upload/drive/v3/files?uploadType=multipart"
    '''%(cmd2["access_token"],name,name)).read()
    
print(cmd4)
executionTime = (time.time() - startTime)
print('Execution time in seconds: ' + str(executionTime))
print('end')
