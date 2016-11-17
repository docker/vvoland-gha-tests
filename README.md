Create a new EC2 instance for attaching `/volumes/repos`:

```
$ aws ec2 run-instances \
  --image-id ami-c11dcba1 \
  --instance-type m4.large \
  --subnet-id subnet-86ca8fe3 \
  --placement AvailabilityZone=us-west-2b \
  --security-group-ids sg-6f04a20b \
  --key-name aws_qa_cf_id_rsa
```

From [instructions](http://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ebs-using-volumes.html),
add to `/etc/fstab` entry to mount, e.g.

```
UUID=abcdef01-8566-42ff-b638-ebe35dca8ab5 /volumes/repos ext4 defaults,nofail 0 0
```
