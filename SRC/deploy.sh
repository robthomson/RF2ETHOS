rsync -rvva --exclude=deploy.sh  * ../RF2ETHOS/
cd ../RF2ETHOS/
find . -name "*.lua" -type f -delete
cd -

