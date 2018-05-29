const aws = require("aws-sdk");
const crypto = require("crypto");

function launchInstance(callback) {
     var userData = "${user_data}";

     new aws.EC2().runInstances({
          IamInstanceProfile: {
               Name: "${site_name}-ec2"
          },
          ImageId: "${ami}",
          InstanceInitiatedShutdownBehavior: "terminate",
          InstanceType: "${instance_type}",
          MaxCount: 1,
          MinCount: 1,
          SecurityGroupIds: [ "${site_name}-disallow-all" ],
          TagSpecifications: [
               {
                    ResourceType: "instance",
                    Tags: [ { Key: "project", Value: "${site_name}" } ]
               },
               {
                    ResourceType: "volume",
                    Tags: [ { Key: "project", Value: "${site_name}" } ]
               }
          ],
          UserData: userData
     }, function(err, data) {
          if (err) {
               returnError(500, callback, "Unable to rebuild site", err);

               return;
          }

          callback(null, {
               body: JSON.stringify({ message: "Started site rebuild" }),
               headers: {
                    "Content-Type": "application/json"
               },
               statusCode: 200
          });
     });
}

function returnError (statusCode, callback, message, err) {
     console.error(message);

     if (err) {
          console.error(err);
     }

     callback(null, {
          body: JSON.stringify({ message: message }),
          headers: {
               "Content-Type": "application/json"
          },
          statusCode: statusCode
     });
}

exports.handler = (event, context, callback) => {
     var expected;

     for (const key in event.headers) {
          if (event.headers.hasOwnProperty(key) && key.toLowerCase() === "x-hub-signature") {
               expected = event.headers[key];

               break;
          }
     }

     if (!expected) {
          returnError(400, callback, "Request does not contain X-Hub-Signature header");

          return;
     }

     // Get the webhook secret from the Parameter Store.

     new aws.SSM().getParameter({
          Name: "${github_secret_parameter_name}",
          WithDecryption: true
     }, function(err, data) {
          if (err) {
               returnError(400, callback, "Invalid or missing webhook secret", err);
          }

          else {
               var actual;
               var hmac;

               // Check if the signatures match per GitHub's docs: https://developer.github.com/webhooks/securing.

               hmac = crypto.createHmac("sha1", data.Parameter.Value);

               hmac.update(event.body, "utf-8");

               actual = "sha1=" + hmac.digest("hex");

               if (actual !== expected) {
                    returnError(400, callback, "Invalid signature");

                    return;
               }

               launchInstance(callback);
          }
     });
};