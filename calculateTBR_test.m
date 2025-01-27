
clear;clc;close all;


interfaceAddress = '127.0.0.1';
interfacePort = 1234;
bytesToRead = 1000;
bufferSize = 1000;
thetaFreqRange = [4, 8];
betaFreqRange = [12, 30];

tbrValues = calculateTBR(interfaceAddress, interfacePort, bytesToRead, bufferSize, thetaFreqRange, betaFreqRange);
