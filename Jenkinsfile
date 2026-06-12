pipeline {
    agent any
    tools {
        jdk 'jdk17'
        nodejs 'node16'
    }
    environment {
        SCANNER_HOME = tool 'mysonar'
        IMAGE_NAME   = 'eshwar933/zomato'
        IMAGE_TAG    = "${BUILD_NUMBER}"
    }
    stages {
        stage('Clean Workspace') {
            steps { cleanWs() }
        }

        stage('Checkout Code') {
            steps {
                git branch: 'main',
                    url: 'https://github.com/eeshwardevops/DevSecOps-E2E-Project.git'
            }
        }

        stage('SonarQube Analysis') {
            steps {
                withSonarQubeEnv('mysonar') {
                    sh '''
                        $SCANNER_HOME/bin/sonar-scanner \
                          -Dsonar.projectName=zomato \
                          -Dsonar.projectKey=zomato
                    '''
                }
            }
        }

        stage('Quality Gate') {
            steps {
                script {
                    waitForQualityGate abortPipeline: false,
                        credentialsId: 'sonar-token'
                }
            }
        }

        stage('Install Dependencies') {
            steps { sh 'npm install' }
        }

        stage('OWASP Dependency Check') {
            steps {
                dependencyCheck additionalArguments: \
                    '--scan ./ --disableYarnAudit --disableNodeAudit',
                    odcInstallation: 'Dp-Check'
                dependencyCheckPublisher pattern: '**/dependency-check-report.xml'
            }
        }

        stage('Trivy FS Scan') {
            steps { sh 'trivy fs . > trivyfs.txt' }
        }

        stage('Docker Build') {
            steps { sh 'docker build -t ${IMAGE_NAME}:${IMAGE_TAG} .' }
        }

        stage('Trivy Image Scan') {
            steps {
                sh 'trivy image ${IMAGE_NAME}:${IMAGE_TAG} > trivy-image.txt'
            }
        }

        stage('Docker Push') {
            steps {
                script {
                    withDockerRegistry(credentialsId: 'docker-password') {
                        sh 'docker push ${IMAGE_NAME}:${IMAGE_TAG}'
                        sh 'docker tag ${IMAGE_NAME}:${IMAGE_TAG} ${IMAGE_NAME}:latest'
                        sh 'docker push ${IMAGE_NAME}:latest'
                    }
                }
            }
        }
        stage('Update Deployment Manifest') {
            steps {
                script {
                    withCredentials([usernamePassword(
                        credentialsId: 'github-token',
                        usernameVariable: 'GIT_USER',
                        passwordVariable: 'GIT_PASS')]) {
                        sh """
                            git clone https://${GIT_USER}:${GIT_PASS}@github.com/eeshwardevops/DevSecOps-E2E-Project.git
                            cd DevSecOps-E2E-Project
                            sed -i "s|image:.*|image: ${IMAGE_NAME}:${IMAGE_TAG}|" kubernetes/deployment.yaml
                            git config user.email ci@pipeline.com
                            git config user.name CI-Pipeline
                            git add kubernetes/deployment.yaml
                            git commit -m "Update image to ${IMAGE_TAG}"
                            git push https://${GIT_USER}:${GIT_PASS}@github.com/eeshwardevops/DevSecOps-E2E-Project.git main
                        """
                    }
                }
            }
        }
    }

    post {
        always {
            archiveArtifacts artifacts: 'trivyfs.txt,trivy-image.txt', allowEmptyArchive: true
        }
    }
}