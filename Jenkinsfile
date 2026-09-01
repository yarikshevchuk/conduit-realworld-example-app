pipeline {
  agent any

  environment {
    DOCKER_HUB_USER = 'shevua'
    AWS_REGION = 'eu-central-1'

    BACKEND_IMAGE = 'conduit-backend'
    FRONTEND_IMAGE = 'conduit-frontend'
  }

  stages {
    stage ('Provision using Terraform') {
      dir('terraform') {
        steps {
          withCredentials([
            string(credentialsId: 'aws-access-key-id', variable: 'AWS_ACCESS_KEY_ID'),
            string(credentialsId: 'aws-secret-access-key', variable: 'AWS_SECRET_ACCESS_KEY')
          ]) {
            echo "Provisioning infrastructure"
            sh 'make'
          }
        }
      }
    }

    stage ('Obtain APP_SERVER_IP') {
      steps {
        dir('terraform') {
          script {
            env.APP_SERVER_IP = sh(script: "terraform output -raw app_server_public_ip", returnStdout: true).trim()
          
            echo "Server public IP: ${env.APP_SERVER_IP}"
          }
        }
      }
    }

    stage ('Wait for EC2 to load') {
      steps {
        sh 'sleep 30'
      }
    }

    stage ('Docker backend image build') {
      steps {
        sh 'docker build -t $BACKEND_IMAGE ./backend'
      }
    }

    stage ('Push backend to Dockerhub') {
      steps {
        withCredentials([usernamePassword(
          credentialsId: 'docker-hub-credentials',
          usernameVariable: 'DOCKER_USER',
          passwordVariable: 'DOCKER_PASS'
        )]) {
          sh """
            echo "$DOCKER_PASS" | docker login -u "$DOCKER_USER" --password-stdin
            docker tag ${BACKEND_IMAGE} ${DOCKER_HUB_USER}/${BACKEND_IMAGE}:${BUILD_NUMBER}
            docker push ${DOCKER_HUB_USER}/${BACKEND_IMAGE}:${BUILD_NUMBER}
          """
        }
      }
    }

    stage ('Docker frontend image build') {
      steps {
        sh 'docker build -t $FRONTEND_IMAGE ./frontend'
      }
    }

    stage ('Push frontend to Dockerhub') {
      steps {
        withCredentials([usernamePassword(
          credentialsId: 'docker-hub-credentials',
          usernameVariable: 'DOCKER_USER',
          passwordVariable: 'DOCKER_PASS'
        )]) {
          sh """
            echo "$DOCKER_PASS" | docker login -u "$DOCKER_USER" --password-stdin
            docker tag ${FRONTEND_IMAGE} ${DOCKER_HUB_USER}/${FRONTEND_IMAGE}:${BUILD_NUMBER}
            docker push ${DOCKER_HUB_USER}/${FRONTEND_IMAGE}:${BUILD_NUMBER}
          """
        }
      }
    }

    stage ('Deploy to EC2') {
      steps {
        sshagent(['app-server-ssh']) {
          sh """
            scp -o StrictHostKeyChecking=no ./docker-compose.yml ubuntu@${env.APP_SERVER_IP}:~/docker-compose.yml

            ssh -o StrictHostKeyChecking=no ubuntu@${env.APP_SERVER_IP} "
              export DOCKER_HUB_USER='${DOCKER_HUB_USER}'
              export BACKEND_IMAGE='${BACKEND_IMAGE}'
              export FRONTEND_IMAGE='${FRONTEND_IMAGE}'
              export BUILD_NUMBER='${BUILD_NUMBER}'

              docker compose pull 
              docker compose up -d
            "
          """
        }
      }
    }

  }

  post {
    always {
      sh 'docker image prune -f'
    }
  }
}