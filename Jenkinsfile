#!/usr/bin/env groovy
pipeline {
  agent {
    kubernetes {
      label validLabel("learning-${env.BRANCH_NAME}") // subsequent builds from the same branch will reuse pods
      idleMinutes 60 // pod will be available to reuse for 1 h
      //Ensures all containers use the same user id as jnlp container to mitigate issue
      //https://github.com/jenkinsci/kubernetes-plugin#pipeline-sh-step-hangs-when-multiple-containers-are-used
      yaml """
apiVersion: v1
kind: Pod
metadata:
  labels:
    purpose: ci
spec:
  securityContext:
    runAsUser: 1000
  containers:
  - name: maven-jdk11
    image: maven:3-jdk-11
    command:
    - sleep
    args:
    - infinity
    volumeMounts:
    - mountPath: /home/jenkins/agent
      name: workspace-volume
  - name: golang
    image: mirror.gcr.io/library/golang:latest
    command:
    - sleep
    args:
    - infinity
    volumeMounts:
    - mountPath: /home/jenkins/agent
      name: workspace-volume
  - name: python
    image: quay.io/matihost/ansible:latest
    command:
    - cat
    tty: true
    volumeMounts:
    - mountPath: /home/jenkins/agent
      name: workspace-volume
  - name: rust
    image: rust
    command:
    - cat
    tty: true
    volumeMounts:
    - mountPath: /home/jenkins/agent
      name: workspace-volume
  - name: ansible
    image: quay.io/matihost/ansible:latest
    command:
    - sleep
    args:
    - infinity
    volumeMounts:
    - mountPath: /home/jenkins/agent
      name: workspace-volume
  - name: kubectl
    image: mirror.gcr.io/bitnami/kubectl:latest
    command:
    - sleep
    args:
    - infinity
    volumeMounts:
    - mountPath: /home/jenkins/agent
      name: workspace-volume
"""
    }
  }
  options{
    buildDiscarder(logRotator(numToKeepStr: '10'))
    timeout(time: 1, unit: 'HOURS')
    skipDefaultCheckout()  // to avoid auto checkout sources matching Jenkinsfile, if skipped pipeline needs to call: checkout scm
    skipStagesAfterUnstable()
    parallelsAlwaysFailFast()
    timestamps()
  }
  triggers {
    pollSCM('H/10 * * * 1-5')
  }
  stages {
    stage('Checkout sources') {
      steps {
        // when no tags info is required
        // checkout scm

        // checkout with tags info so that git describe is able to work
        checkout([
          $class                           : 'GitSCM',
          branches                         : scm.branches,
          doGenerateSubmoduleConfigurations: scm.doGenerateSubmoduleConfigurations,
          extensions                       : scm.extensions + [[$class: 'CloneOption', noTags: false]],
          userRemoteConfigs                : scm.userRemoteConfigs,
        ])
      }
    }
    stage('Build') {
      parallel {
        stage('Build :: Java') {
          steps {
              container("maven-jdk11"){
                dir("java"){
                  echo "Building ${pwd()}..."
                  sh """
                  mvn -s .mvn/settings.xml clean install
                  """
                }
              }
          }
          post{
            always {
              dir("java"){
                archiveArtifacts artifacts: '**/target/*.jar', fingerprint: true
                junit '**/target/surefire-reports/*.xml'
              }
            }
          }
        }
        stage('Build :: Project Euler') {
          steps {
            container("maven-jdk11"){
              dir("algorithms/project-euler"){
                echo "Building ${pwd()}..."
                sh """
                mvn -s .mvn/settings.xml clean install
                """
              }
            }
          }
          post{
            always {
              dir("algorithms/project-euler"){
                archiveArtifacts artifacts: '**/target/*.jar', fingerprint: true
              }
            }
          }
        }
        stage('Build :: Golang') {
          steps {
            container("golang"){
              dir("go"){
                echo "Building ${pwd()}..."
                sh """
                  export GOCACHE=/home/jenkins/agent/workspace/.gocache
                  make build
                """
              }
            }
          }
          post{
            always {
              dir("go"){
                archiveArtifacts artifacts: '**/language', fingerprint: true
              }
            }
          }
        }
        stage('Build :: Rust') {
          steps {
            container("rust"){
              dir("rust/guessing_game"){
                echo "Building ${pwd()}..."
                sh """
                  make build
                """
              }
            }
          }
        }
        stage('Build :: Python') {
          steps {
            container("python"){
              dir("python/apps/exchange-rate"){
                echo "Building ${pwd()}..."
                sh """
                  pipenv install --dev -e .
                  pipenv run pylint src/ tests/
                  python3 setup.py build
                  pipenv run exchange-rate CHF
                """
              }
            }
          }
        }
        stage('Build :: Ansible') {
          steps {
            container("ansible"){
              dir("ansible/learning"){
                echo "Building ${pwd()}..."
                sh """
                  ansible-playbook dictionaries.yaml -v
                """
              }
            }
          }
        }
        stage('Build :: Kubectl') {
          steps {
            container("kubectl"){
              echo "Running kubectl ${pwd()}..."
              sh """
                kubectl version
              """
            }
          }
        }
      }
    }
  }
}

/**
 * Helper method to ensure label given to pod follow K8S naming rules
 */
def validLabel(String str){
  str = str.replaceAll('[^A-Za-z0-9]','-')
  if (str.length() > 63){
    str = str.substring(0, 63)
  }
  return str
}
