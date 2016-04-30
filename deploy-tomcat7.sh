echo "Building..." 

# clean
rm -rf deployment

# SETUP VARIABLES 
TAG=${TRAVIS_TAG:=0.0.0}
DIR="$(cd "$(dirname "$0")" && pwd)"
CONTEXT=${CONTEXT:="ROOT"}

# work with sources as managed by git 
mkdir $DIR/deployment
cd $DIR 
git archive --format zip --output $DIR/deployment/sources.zip master
mkdir $DIR/deployment/sources
unzip $DIR/deployment/sources.zip -d $DIR/deployment/sources/. 

# sbt package 
cd $DIR/deployment/sources
./sbt package
cd $DIR/deployment/sources/target/scala-2.11/
APP=$(ls *_2.11-${TAG}.war | sed 's/\(.*\)_2.11-.*\.war/\1/')

# download TOMCAT 
mkdir $DIR/deployment/tmp
cd $DIR/deployment/tmp
curl -L -J -O https://github.com/rehei/tomcat7-rehei/releases/download/7.0.63-06/apache-tomcat-7.0.63-windows-x64-rehei.zip
unzip apache-tomcat-7.0.63-windows-x64-rehei.zip -d $DIR/deployment/tomcat7-${APP}
cp $DIR/deployment/sources/target/scala-2.11/${APP}_2.11-${TAG}.war $DIR/deployment/tomcat7-${APP}/webapps/${CONTEXT}.war
rm -rf $DIR/deployment/tmp

# copy sources to TOMCAT root 
cp $DIR/sources.zip $DIR/deployment/tomcat7-${APP}/.

# Unpack package to TOMCAT webapps 
mv $DIR/deployment/tomcat7-${APP}/webapps/${CONTEXT}.war $DIR/deployment/tomcat7-${APP}/webapps/${CONTEXT}.zip
unzip $DIR/deployment/tomcat7-${APP}/webapps/${CONTEXT}.zip -d $DIR/deployment/tomcat7-${APP}/webapps/${CONTEXT}
rm -rf $DIR/deployment/tomcat7-${APP}/webapps/${CONTEXT}.zip
cd $DIR/deployment
zip -r $DIR/deployment/tomcat7-${APP}.zip tomcat7-${APP}

echo "Done" 

