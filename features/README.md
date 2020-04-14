<p align="center">
    <a href="https://beacon-support-staging.herokuapp.com/">
        <img src="https://github.com/wearefuturegov/beacon/blob/master/app/assets/images/beacon.png?raw=true" width="350px" />               
    </a>
</p>
  
<p align="center">
    <em>Record and triage needs, get people the right support</em>         
</p>

---

# Acceptance Test Suite

The acceptance tests run with the following command
```
bundle exec cucumber
```

To run the acceptance tests in firefox, set the BROWSER environment variable and run
```
BROWSER=firefox bundle exec cucumber
```

To run the acceptance tests in chrome (via chromedriver),
 set the BROWSER environment variable and run
```
BROWSER=remote_chrome bundle exec cucumber
```
This requires https://chromedriver.chromium.org/ to be running locally


To run the acceptance tests with browserstack, the following needs to be set

| env variable       | example value                                           |
|--------------------|---------------------------------------------------------|
| BS_USERNAME        | Your browserstack username, e.g. username123            |
| BS_AUTHKEY         | Your browserstack access key (base64)                   |
| BS_BROWSER         | The browser to use, e.g. 'Firefox'                      |
| BS_BROWSER_VERSION | The browser version to use, e.g. '75.0 beta'            |
| BS_OS              | The operating system to run on, e.g. 'OS X'             |
| BS_OS_VERSION      | The operating system version to run on, e.g. 'Catalina' |