# Hatchet.IO - Deploy

Hatchet can be deployed to most VPS infrastructures. For simplicity we'll focus on Amazon AWS.

You can get started quickly using the AWS Image provided that gives you a Single Server implementation of Hatchet. Although this somewhat defeats the purpose as Hatchet is designed to use a separate Redis server, etc so that it can be scaled to a network of machines easily. For a multi machine implementation feel free to contact us at Inlight Media (ben@inlight.com.au).

Search the Amazon public marketplace for "hatchet.io-single".

When creating the instance your security group will need to have ports 80, 5223 and 5224 open to all.

Once you have the AWS Image running ssh in using these credentials:

```
User: hatchet
Password: rKCDWdvTmzboAEkZpZDgOk0HI0FQaxQsXYWv
```

Straight up, change the password with `passwd` command.

Then run:

```
sudo /etc/init.d/hatchet-rest start
sudo /etc/init.d/hatchet-publishers start
sudo /etc/init.d/hatchet-subscribers start
```

That's it on the box. You can assign an Elastic IP and domain name to it. 

Then head on over to http://hatchet.io - enter your domain/ip in the "Host" input and you can begin managing your instance.
