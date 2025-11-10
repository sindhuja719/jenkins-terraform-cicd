pipeline {
    agent { label 'linux-agent' }

    environment {
        AWS_CREDENTIALS = credentials('aws-creds')           // Jenkins credential ID for AWS Access Key & Secret
        IMAGE_NAME = "flask-app"
        IMAGE_TAG = "v1.${BUILD_NUMBER}"
        REGION = "us-east-1"
        ACCOUNT_ID = "312596057535"
        ECR_REPO = "${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com/${IMAGE_NAME}"
        TF_DIR = "terraform"                                // Terraform directory path in your repo
    }

    triggers {
        githubPush() // 🔔 Trigger pipeline on every GitHub push
    }

    stages {

        stage('Checkout Code') {
            steps {
                echo "📥 Checking out source code..."
                git branch: 'main', url: 'https://github.com/sindhuja719/jenkins-terraform-cicd.git'
            }
        }

        stage('Install Dependencies') {
            steps {
                echo "⚙️ Ensuring required tools are available..."
                sh '''
                    docker --version || (echo "Installing Docker..." && sudo apt update -y && sudo apt install -y docker.io)
                    terraform version || (echo "Installing Terraform..." && curl -fsSL https://releases.hashicorp.com/terraform/1.9.7/terraform_1.9.7_linux_amd64.zip -o tf.zip && unzip tf.zip && sudo mv terraform /usr/local/bin/ && rm tf.zip)
                    aws --version || (echo "Installing AWS CLI..." && curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" && unzip awscliv2.zip && sudo ./aws/install)
                '''
            }
        }

        stage('Login to AWS ECR') {
            steps {
                script {
                    echo "🔐 Logging into AWS ECR..."
                    withAWS(credentials: 'aws-creds', region: "${REGION}") {
                        sh '''
                            aws ecr get-login-password --region $REGION | docker login --username AWS --password-stdin $ECR_REPO
                        '''
                    }
                }
            }
        }

        stage('Build Docker Image') {
            steps {
                script {
                    echo "🛠 Building Docker image..."
                    sh '''
                        docker build -t $IMAGE_NAME:$IMAGE_TAG .
                        docker tag $IMAGE_NAME:$IMAGE_TAG $ECR_REPO:$IMAGE_TAG
                    '''
                }
            }
        }

        stage('Push Docker Image to ECR') {
            steps {
                script {
                    echo "🚀 Pushing image to AWS ECR..."
                    withAWS(credentials: 'aws-creds', region: "${REGION}") {
                        sh '''
                            docker push $ECR_REPO:$IMAGE_TAG
                        '''
                    }
                }
            }
        }

        stage('Deploy with Terraform') {
            steps {
                dir("${TF_DIR}") {
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
        always {
            echo "🧹 Cleaning up Docker images and cache..."
            sh '''
                docker system prune -f
            '''
        }
        success {
            echo "✅ SUCCESS: Build, Push, and Deploy completed successfully!"
        }
        failure {
            echo "❌ FAILURE: Pipeline failed. Check Jenkins logs for details."
        }
    }
}
