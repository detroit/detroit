
resources = configuation('resources')
actions   = configuation('actions')

resources.each do |name, options|
  klass = options.delete('class')
  define_method "resource_#{name}" do
    @resources[options] ||= send(type, options)
  end
end

actions.each do |action, procedures|
  define_method "action_#{action}" do
    procedures.each do |procedure|
      rsc = procedure.delete('resource')
      act = procedure.delete('action')
      send("resource_#{rsc}").send(act, procedure)
    end
  end
end

