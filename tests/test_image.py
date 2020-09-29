import os
import pytest
import subprocess
import testinfra


@pytest.fixture(scope='session')
def host(request):
    # set the working directory to where the Dockerfile lives
    path = os.path.dirname(os.path.abspath(__file__)) + "/../"

    subprocess.check_call(['docker', 'build', '-t', 'robertbeal/gogs', '.'], cwd=path)
    id = subprocess.check_output(
        ['docker', 'run', '--rm', '-d', 'robertbeal/gogs'], cwd=path).decode().strip()

    yield testinfra.get_host("docker://" + id)

    subprocess.check_call(['docker', 'rm', '-f', id])


def test_system(host):
    assert host.system_info.distribution == 'alpine'


def test_gogs_process(host):
    assert host.process.get(
        user='git').args == '/app/gogs web --config /config/app.ini'


def test_cron_process(host):
    assert host.process.get(
        user='root', comm='crond').args == '/usr/sbin/crond -fS'


def test_version(host):
    assert os.environ.get('VERSION', '0.12.2') in host.check_output("/app/gogs --version")


def test_port(host):
    assert host.socket("tcp://0.0.0.0:3000").is_listening


def test_user(host):
    assert host.user('git').uid == 801
    assert host.user('git').gid == 801
    assert host.user('git').shell == '/bin/bash'


def test_user_is_locked(host):
    assert 'git L ' in host.check_output('passwd --status git')


def test_app_folder(host):
    folder = '/app'
    assert host.file(folder).exists
    assert host.file(folder).user == 'git'
    assert host.file(folder).group == 'git'
    assert oct(host.file(folder).mode) == '0o550'


def test_ssh_config(host):
    host.file("/etc/ssh/sshd_config").exists


def test_nsswitch_config(host):
    host.file("/etc/nsswitch.conf").exists


@pytest.mark.parametrize('package', [
    ('bash'),
    ('ca-certificates'),
    ('linux-pam'),
    ('openssh'),
    ('shadow'),
])
def test_installed_dependencies(host, package):
    assert host.package(package).is_installed
