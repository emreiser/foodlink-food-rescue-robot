if Rails.env.production?
  Webapp::Application.config.secret_token = 'dev_0aac6asdfalsdfjkalsdfkdlsfljkasljkdflkajsflkjsdlkjflksdfjdsklf'
else
  Webapp::Application.config.secret_token = 'dev_0aac6asdfalsdfjkalsdfkdlsfljkasljkdflkajsflkjsdlkjflksdfjdsklf'
end
