pipeline {
    agent { label 'linux-agent' } // your agent node label

    environment {
        AWS_CREDENTIALS = credentials('aws-creds')
        IMAGE_NAME = "flask-app"
        IMAGE_TAG = "v1"
        ECR_REPO = "312596057535.dkr.ecr.us-east-1.amazonaws.com/flask-app"
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
                    sh "docker build -t ${IMAGE_NAME}:${IMAGE_TAG} ."
                }
            }
        }

        stage('Push to AWS ECR') {
            steps {
                withAWS(credentials: 'aws-creds', region: 'us-east-1') {
                    sh """
                        aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin $ECR_REPO
                        docker tag ${IMAGE_NAME}:${IMAGE_TAG} $ECR_REPO:${IMAGE_TAG}
                        docker push $ECR_REPO:${IMAGE_TAG}
                    """
                }
            }
        }

        stage('Deploy with Terraform') {
            steps {
                dir('terraform') {
                    sh 'terraform init'
                    sh 'terraform apply -auto-approve'
                }
            }
        }
    }

    post {
        success {
            echo "✅ Pipeline completed successfully!"
        }
        failure {
            echo "❌ Pipeline failed. Check the console output for details."
        }
    }
}
