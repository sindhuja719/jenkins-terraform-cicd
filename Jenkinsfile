pipeline {
    agent { label 'linux-agent' }

    environment {
        AWS_CREDENTIALS = credentials('aws-creds')   // Jenkins credentials ID for AWS
        IMAGE_NAME = "flask-app"
        IMAGE_TAG = "v1"
        ECR_REPO = "312596057535.dkr.ecr.us-east-1.amazonaws.com/flask-app"
        REGION = "us-east-1"
    }

    stages {

        stage('Checkout Code') {
            steps {
                git branch: 'main', url: 'https://github.com/sindhuja719/jenkins-terraform-cicd.git'
            }
        }

        stage('Build Docker Image') {
            steps {
                script {
                    echo "🛠 Building Docker image..."
                    sh 'docker build -t $IMAGE_NAME:$IMAGE_TAG .'
                }
            }
        }

        stage('Push to AWS ECR') {
            steps {
                script {
                    echo "📦 Logging into AWS ECR and pushing image..."
                    withAWS(credentials: 'aws-creds', region: "${REGION}") {
                        sh '''
                            aws ecr get-login-password --region $REGION | docker login --username AWS --password-stdin $ECR_REPO
                            docker tag $IMAGE_NAME:$IMAGE_TAG $ECR_REPO:$IMAGE_TAG
                            docker push $ECR_REPO:$IMAGE_TAG
                        '''
                    }
                }
            }
        }

        stage('Deploy with Terraform') {
            steps {
                dir('terraform') {
                    sh '''
                        terraform init -input=false
                        terraform apply -auto-approve
                    '''
                }
            }
        }
    }

    post {
        success {
            echo "✅ Pipeline completed successfully! Image pushed and deployed to AWS."
        }
        failure {
            echo "❌ Pipeline failed. Check the console logs for more details."
        }
    }
}
