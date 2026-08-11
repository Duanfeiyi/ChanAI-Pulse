function  isValid = isValidEmail(email)
            % 定义电子邮件的正则表达式
            pattern = '^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$';
            % 使用regexp函数检查电子邮件格式
            isValid = ~isempty(regexp(email, pattern, 'once'));
end     