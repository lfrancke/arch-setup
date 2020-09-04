from ansible.module_utils.basic import *


def package_installed(module, package_name):
  """
  Determine if the package is already installed
  """
  cmd = ['pacman', '-Q', package_name]
  exit_code, _, _ = module.run_command(cmd, check_rc=False)
  return exit_code == 0


def install_packages(module, packages, state):
  """
  Install the specified packages
  """

  changed_iter = False

  for package in packages:
    if state == 'present':
      if package_installed(module, package):
        rc = 0
        continue

      command = ['yay', '-S', '--noconfirm', '--needed', '--cleanafter']
      command.append(package)
      rc, out, err = module.run_command(command, check_rc=True)
      changed_iter = changed_iter or not (out == '' or '-- skipping' in out or 'nothing to do' in out)

  message = 'installed package(s)' if changed_iter else 'package(s) already installed'

  module.exit_json(
     changed=changed_iter,
     msg=message if not rc else err,
     rc=rc,
  )


def upgrade(module):
    """
    Upgrade the whole system
    """
    command = ['yay', '-S', '-y', '-u', '--noconfirm', '--needed', '--cleanafter']

    rc, out, err = module.run_command(command, check_rc=True)

    module.exit_json(
        changed=not (out == '' or 'nothing to do' in out or 'No AUR updates found' in out),
        msg='upgraded system'
    )


def run_module(module):
  params = module.params

  if params.get('upgrade', False):
    upgrade(module)
  else:
    install_packages(module, params['name'], params['state'])


def main():
  module = AnsibleModule(
    argument_spec={
      'name':    {'type': 'list', },
      'state':   {'default': 'present', 'choices': ['present', 'latest'], },
      'upgrade': {'type': 'bool'}
    },
    mutually_exclusive=[['name', 'upgrade']],
    required_one_of=[['name', 'upgrade']]
  )
  run_module(module)

if __name__ == '__main__':
  main()
