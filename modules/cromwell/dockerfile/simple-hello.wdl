task echoHello{
    command {
        echo "Hello, AWS!"
    }
    runtime {
        dockerImage: "ubuntu:latest"
        memorys: "512Mi"
        cpus: 1
    }

}

workflow printHelloAndGoodbye {
    call echoHello
}