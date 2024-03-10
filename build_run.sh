#!/bin/bash

docker stop nzedb-container
docker rm nzedb-container
docker rmi nzedb-image:latest

docker build -t nzedb-image:latest .
