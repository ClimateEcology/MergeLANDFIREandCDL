#!/bin/bash

# make tar file to send to Google drive
tar cvf 2017MergeCDLLANDFIRE.tar 2017

 # how to send tar to google drive (execute this in project folder)
./curlgoogle.py ../../../../90daydata/geoecoservices/MergeLANDFIREandCDL/StateRasters/2017MergeCDLLANDFIRE.tar
