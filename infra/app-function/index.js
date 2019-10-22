/**
 * Given either start or stop in the data the start/stop the vm
 *
 * @param {!express:Request} req HTTP request context.
 * @param {!express:Response} res HTTP response context.
 */
// API DOCUMENTATION: https://googleapis.dev/nodejs/compute/latest/Compute.html#getVMs
const Compute = require("@google-cloud/compute");
const escapeHtml = require("escape-html");

const compute = new Compute();

async function get_vm_in_project() {
  // This is filtering all VMS in the project $GCLOUD_PROJECT
  const options = {
    filter: "name eq gist-poller"
  };
  const vm = await compute.getVMs(options);
  return vm[0];
}

stopvm = vm => {
  stopstartvm(vm, "stop");
};

startvm = vm => {
  stopstartvm(vm, "start");
};

stopstartvm = (vm, action) => {
  vm.forEach(vm => {
    // console.log(vm);
    if (action === "stop") {
      console.log("Stopping VM: ", vm.name);
      vm.stop((err, operation, apiResponse) => {
        if (err) {
          console.log("err", err);
        } else {
          console.log("Stopped VM: ", vm.name);
        }
      });
    } else {
      console.log("Starting VM: ", vm.name);
      vm.start((err, operation, apiResponse) => {
        if (err) {
          console.log("err", err);
        } else {
          console.log("Started VM: ", vm.name);
        }
      });
    }
  });
};

check_user_token = user_token => {
  console.log("Expected user token: ", process.env.USER_TOKEN);
  console.log("Provided user token: ", user_token);
  return process.env.USER_TOKEN === user_token;
};

exports.stop_vm = async (req, res) => {
  console.log("received body data: ", req.body);
  if (!check_user_token(escapeHtml(req.body.userToken))) {
    console.log("Bad token provided");
    res.status(401).send("Bad request!");
    return;
  }

  const vm = await get_vm_in_project().catch(console.error);
  if (vm) {
    stopvm(vm);
  }
  res.status(200).send("Success!");
};

exports.start_vm = async (req, res) => {
  console.log("received body data: ", req.body);
  if (!check_user_token(escapeHtml(req.body.userToken))) {
    console.log("Bad token provided");
    res.status(401).send("Bad request!");
    return;
  }

  const vm = await get_vm_in_project().catch(console.error);
  if (vm) {
    startvm(vm);
  }
  res.status(200).send("Success!");
};

exports.main = async () => {
  const vm = await get_vm_in_project().catch(console.error);
  const vmStatus = vm[0].metadata.status;

  console.log(vmStatus);

  if (vm) {
    stopvm(vm);
  }

  return vm;
};

if (module === require.main) {
  exports.main();
}
