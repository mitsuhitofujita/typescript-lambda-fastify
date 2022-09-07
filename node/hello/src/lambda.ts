import awsLambdaFastify from "@fastify/aws-lambda";
import { app } from "./app"

const proxy = awsLambdaFastify(app)
exports.handler = proxy
