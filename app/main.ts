import { Construct } from 'constructs';
import { App, TerraformStack } from 'cdktf';
import { LocalProvider } from '@cdktf/provider-local/lib/provider/index.js';
import { File } from '@cdktf/provider-local/lib/file/index.js';

class MyStack extends TerraformStack {
  constructor(scope: Construct, id: string) {
    super(scope, id);

    new LocalProvider(this, "local");

    new File(this, "hello", {
      filename: "/tmp/hello.txt",
      content: "Hello, CDKTF with OpenTofu!",
    });
  }
}

const app = new App();
new MyStack(app, "opentofu-cdktf-site");
app.synth();