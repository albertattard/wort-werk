apiVersion: apps/v1
kind: Deployment
metadata:
  name: wortwerk-${APP_SLOT}
  namespace: ${APP_NAMESPACE}
  labels:
    app.kubernetes.io/name: wortwerk
    app.kubernetes.io/part-of: wortwerk
    app.kubernetes.io/slot: ${APP_SLOT}
spec:
  replicas: 2
  revisionHistoryLimit: 2
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxUnavailable: 0
      maxSurge: 1
  selector:
    matchLabels:
      app.kubernetes.io/name: wortwerk
      app.kubernetes.io/slot: ${APP_SLOT}
  template:
    metadata:
      labels:
        app.kubernetes.io/name: wortwerk
        app.kubernetes.io/part-of: wortwerk
        app.kubernetes.io/slot: ${APP_SLOT}
    spec:
      imagePullSecrets:
        - name: wortwerk-registry
      containers:
        - name: wortwerk
          image: ${APP_IMAGE}
          imagePullPolicy: Always
          envFrom:
            - secretRef:
                name: wortwerk-runtime
          ports:
            - name: http
              containerPort: 8080
          readinessProbe:
            httpGet:
              path: /actuator/health/readiness
              port: http
            initialDelaySeconds: 10
            periodSeconds: 10
            timeoutSeconds: 2
            failureThreshold: 6
          livenessProbe:
            httpGet:
              path: /actuator/health/liveness
              port: http
            initialDelaySeconds: 30
            periodSeconds: 20
            timeoutSeconds: 2
            failureThreshold: 3
          startupProbe:
            httpGet:
              path: /actuator/health/readiness
              port: http
            periodSeconds: 5
            timeoutSeconds: 2
            failureThreshold: 24
