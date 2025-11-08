pipeline {
    agent { label 'linux-agent' }

    environment {
        AWS_CREDENTIALS = credentials('aws-creds')
        IMAGE_NAME = "flask-app"
        IMAGE_TAG = "v1.${BUILD_NUMBER}"
        REGION = "us-east-1"
        ECR_REPO = "312596057535.dkr.ecr.us-east-1.amazonaws.com/flask-app"
    }

    triggers {
        githubPush()  // 🔔 Webhook trigger - runs on every GitHub push
    }

    stages {

        stage('Checkout Code') {
            steps {
                echo "📥 Checking out source code..."
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
                    echo "🚀 Logging in and pushing image to AWS ECR..."
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
                    echo "⚙️ Running Terraform deployment..."
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
            echo "✅ SUCCESS: Build, Push, and Deploy completed successfully!"
        }
        failure {
            echo "❌ FAILURE: Pipeline failed. Check console output for details."
        }
    }
}
