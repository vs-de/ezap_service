#!/bin/bash
INIT_FILE="$EZAP_ROOT/lib/loader.rb"

ezap_eval() { 
  ruby -r"$INIT_FILE" <<< "$@"
}
ezap_run() {
  ruby -r"$INIT_FILE" "$@"
}

usage(){

  cat <<HELP

  << -- e z a p -- >>

usage:
  ezap (s)tart [<service|web_app>] name]
  ezap stop/(h)alt [service]
  ezap (r)un <file/args to 'ruby'>
  ezap (e)val <ruby-expression>
  ezap (c)onsole
  //TODO: ezap (g)enerate <service> <name>
  //TODO: ezap (g)enerate <web_app> <controller|view> <name>
  //TODO: ezap (i)nstall [args]
  ezap (h)elp

HELP

}
case $1 in
  r|run)
    shift
    #echo "running in Ezap context..."
    ezap_run "$@"
  ;;
  e|eval)
    shift
    #echo "running in Ezap context..."
    ezap_eval "$@"
  ;;
  h|halt|stop)
    ezap_eval 'Ezap::Service::GlobalMaster.shutdown'
  ;;
  s|start)
    if [[ "$2" == "service" ]] ; then
      ruby -r"$INIT_FILE" -r$EZAP_ROOT/services/$3/ezap_service.rb <<< "eval('$3""_service'.camelize).new.start"
    elif [[ "$2" == "web_app" ]] ; then
      ruby -r"$INIT_FILE" -r$EZAP_ROOT/web_apps/$3/ezap_web_app.rb <<< "eval('$3""_web_app'.camelize).new.start"
    elif [[ "$2" == ""  ]] ; then
      ezap_eval 'Ezap::Service::GlobalMaster.start'
    else
      usage
    fi
  ;;
  c|console)
    irb -r $EZAP_ROOT/lib/console_defs.rb
  ;;
  i|install)
    shift
    ruby $EZAP_ROOT/lib/installer.rb "$@"
  ;;
  g|generate)
    shift
    ruby $EZAP_ROOT/lib/generator.rb "$@"
  ;;
  *)
    usage

esac
