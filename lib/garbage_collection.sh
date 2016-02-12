#!/bin/sh
#
ps ax | grep -v 'grep.*ecs:gc_anonymous_participants' | grep -q 'rake ecs:gc_anonymous_participants' || RAILS_ENV=production bundle exec rake ecs:gc_anonymous_participants
ps ax | grep -v 'grep.*ecs:gc_sys_auths' | grep -q 'rake ecs:gc_sys_auths' || RAILS_ENV=production bundle exec rake ecs:gc_sys_auths
ps ax | grep -v 'grep.*ecs:gc_sub_participants' | grep -q 'rake ecs:gc_sub_participants' || RAILS_ENV=production bundle exec rake ecs:gc_sub_participants
ps ax | grep -v 'grep.*vip:gc_exercises' | grep -q 'rake vip:gc_exercises' || RAILS_ENV=production bundle exec rake vip:gc_exercises
ps ax | grep -v 'grep.*vip:gc_evaluations' | grep -q 'rake vip:gc_evaluations' || RAILS_ENV=production bundle exec rake vip:gc_evaluations
ps ax | grep -v 'grep.*vip:gc_results' | grep -q 'rake vip:gc_results' || RAILS_ENV=production bundle exec rake vip:gc_results
ps ax | grep -v 'grep.*vip:gc_solutions' | grep -q 'rake vip:gc_solutions' || RAILS_ENV=production bundle exec rake vip:gc_solutions
