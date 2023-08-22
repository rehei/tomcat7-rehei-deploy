echo "Building..." 

# Setup VARIABLES
URL="https://github.com/rehei/tomcat7-rehei/releases/download/7.0.63-10/apache-tomcat-7.0.63-windows-x64-rehei.zip" 
TAG=${TAG:=0.0.0}
CONTEXT=${CONTEXT:="ROOT"}
PORT=${PORT:="8080"}
BRANCH=${BRANCH:="master"}

DIR="$(cd "$(dirname "$0")" && pwd)"
DEPLOYMENT=$DIR/../$(basename $DIR)-deployment

# CLEAN
rm -rf $DEPLOYMENT

# BUILD 
mkdir $DEPLOYMENT
cd $DIR 

# Work with sources as managed by git 
git archive --format zip --output $DEPLOYMENT/sources.zip $BRANCH
mkdir $DEPLOYMENT/sources
unzip $DEPLOYMENT/sources.zip -d $DEPLOYMENT/sources/. 

# sbt package 
cd $DEPLOYMENT/sources
./sbt package
cd $DEPLOYMENT/sources/target/scala-2.11/

# More VARIABLES

APP=$(ls *_2.11-${TAG}.war | sed 's/\(.*\)_2.11-.*\.war/\1/')
TOMCAT=tomcat7-${APP}-${PORT}

# Download TOMCAT 
mkdir $DEPLOYMENT/tmp
cd $DEPLOYMENT/tmp
curl -L -J -O $URL
unzip apache-tomcat-7.0.63-windows-x64-rehei.zip -d $DEPLOYMENT/${TOMCAT}
cp $DEPLOYMENT/sources/target/scala-2.11/${APP}_2.11-${TAG}.war $DEPLOYMENT/${TOMCAT}/webapps/${CONTEXT}.war
rm -rf $DEPLOYMENT/tmp

# Copy sources to TOMCAT root 
cp $DIR/sources.zip $DEPLOYMENT/tomcat7-${APP}/.

# Unpack package to TOMCAT webapps 
mv $DEPLOYMENT/${TOMCAT}/webapps/${CONTEXT}.war $DEPLOYMENT/${TOMCAT}/webapps/${CONTEXT}.zip
unzip $DEPLOYMENT/${TOMCAT}/webapps/${CONTEXT}.zip -d $DEPLOYMENT/${TOMCAT}/webapps/${CONTEXT}
rm -rf $DEPLOYMENT/${TOMCAT}/webapps/${CONTEXT}.zip

# Adjust TOMCAT config
cd $DEPLOYMENT
curl -L -J -O https://github.com/rehei/tomcat7-rehei-xslt/releases/download/0.6.0/server.xslt
SERVER_XML=$DEPLOYMENT/${TOMCAT}/conf/server.xml
saxon-xslt -o ${SERVER_XML} ${SERVER_XML} server.xslt port=${PORT}

curl -L -J -O https://github.com/rehei/tomcat7-rehei-xslt/releases/download/0.6.0/context.xslt
CONTEXT_XML=$DEPLOYMENT/${TOMCAT}/conf/context.xml
saxon-xslt -o ${CONTEXT_XML} ${CONTEXT_XML} context.xslt

# Package everything into one zip file 
cd $DEPLOYMENT
zip -r $DEPLOYMENT/${TOMCAT}.zip ${TOMCAT}

echo "Done" 

