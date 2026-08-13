package com.eventsuganda.otp.config;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.BeansException;
import org.springframework.beans.factory.config.BeanFactoryPostProcessor;
import org.springframework.beans.factory.config.ConfigurableListableBeanFactory;
import org.springframework.context.EnvironmentAware;
import org.springframework.context.annotation.Configuration;
import org.springframework.core.env.Environment;

@Configuration
public class DatabaseLogConfig implements BeanFactoryPostProcessor, EnvironmentAware {

    private static final Logger log = LoggerFactory.getLogger(DatabaseLogConfig.class);

    private Environment env;

    @Override
    public void setEnvironment(Environment environment) {
        this.env = environment;
    }

    @Override
    public void postProcessBeanFactory(ConfigurableListableBeanFactory beanFactory) throws BeansException {
        String url = env.resolvePlaceholders("${spring.datasource.url:UNSET}");
        String user = env.resolvePlaceholders("${spring.datasource.username:UNSET}");
        String pass = env.resolvePlaceholders("${spring.datasource.password:UNSET}");
        log.warn("RESOLVED_DB url={} user={} passSet={} profile={}",
            url,
            user,
            !pass.equals("UNSET") && !pass.isEmpty() && !pass.contains("${"),
            String.join(",", env.getActiveProfiles()));
    }
}
