echo "Building..." 

# Clean
rm -rf deployment

# Setup VARIABLES 
TAG=${TRAVIS_TAG:=0.0.0}
CONTEXT=${CONTEXT:="ROOT"}
PORT=${PORT:="8080"}
BRANCH=${BRANCH:="master"}

DIR="$(cd "$(dirname "$0")" && pwd)"

# Work with sources as managed by git 
mkdir $DIR/deployment
cd $DIR 
git archive --format zip --output $DIR/deployment/sources.zip $BRANCH
mkdir $DIR/deployment/sources
unzip $DIR/deployment/sources.zip -d $DIR/deployment/sources/. 

# sbt package 
cd $DIR/deployment/sources
./sbt package
cd $DIR/deployment/sources/target/scala-2.11/

# More VARIABLES

APP=$(ls *_2.11-${TAG}.war | sed 's/\(.*\)_2.11-.*\.war/\1/')
TOMCAT=tomcat7-${APP}-${PORT}

# Download TOMCAT 
mkdir $DIR/deployment/tmp
cd $DIR/deployment/tmp
curl -L -J -O https://github.com/rehei/tomcat7-rehei/releases/download/7.0.63-08/apache-tomcat-7.0.63-windows-x64-rehei.zip
unzip apache-tomcat-7.0.63-windows-x64-rehei.zip -d $DIR/deployment/${TOMCAT}
cp $DIR/deployment/sources/target/scala-2.11/${APP}_2.11-${TAG}.war $DIR/deployment/${TOMCAT}/webapps/${CONTEXT}.war
rm -rf $DIR/deployment/tmp

# Copy sources to TOMCAT root 
cp $DIR/sources.zip $DIR/deployment/tomcat7-${APP}/.

# Unpack package to TOMCAT webapps 
mv $DIR/deployment/${TOMCAT}/webapps/${CONTEXT}.war $DIR/deployment/${TOMCAT}/webapps/${CONTEXT}.zip
unzip $DIR/deployment/${TOMCAT}/webapps/${CONTEXT}.zip -d $DIR/deployment/${TOMCAT}/webapps/${CONTEXT}
rm -rf $DIR/deployment/${TOMCAT}/webapps/${CONTEXT}.zip

# Adjust TOMCAT config
cd $DIR/deployment
curl -L -J -O https://github.com/rehei/tomcat7-rehei-xslt/releases/download/0.4.0/server.xslt
SERVER_XML=$DIR/deployment/${TOMCAT}/conf/server.xml
saxon-xslt -o ${SERVER_XML} ${SERVER_XML} server.xslt port=${PORT}

curl -L -J -O https://github.com/rehei/tomcat7-rehei-xslt/releases/download/0.4.0/context.xslt
CONTEXT_XML=$DIR/deployment/${TOMCAT}/conf/context.xml
saxon-xslt -o ${CONTEXT_XML} ${CONTEXT_XML} context.xslt

# Package everything into one zip file 
cd $DIR/deployment
zip -r $DIR/deployment/${TOMCAT}.zip ${TOMCAT}

echo "Done" 

