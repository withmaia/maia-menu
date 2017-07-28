metaserve --bounce /index.html
metaserve --bounce /js/app.js
coffee ~/Projects/metaserve/src/metaserve.coffee --bounce /css/app.css
AWS_DEFAULT_PROFILE=prontotype AWS_REGION=us-east-1 aws s3 cp ./js/app.js.bounced s3://prontotype-static/maia-menu/js/app.js --content-type application/javascript
AWS_DEFAULT_PROFILE=prontotype AWS_REGION=us-east-1 aws s3 cp ./css/app.css.bounced s3://prontotype-static/maia-menu/css/app.css --content-type text/css
AWS_DEFAULT_PROFILE=prontotype AWS_REGION=us-east-1 aws s3 cp ./index.html.bounced s3://prontotype-static/maia-menu/index.html --content-type text/html
AWS_DEFAULT_PROFILE=prontotype AWS_REGION=us-east-1 aws s3 sync ./images s3://prontotype-static/maia-menu/images/
