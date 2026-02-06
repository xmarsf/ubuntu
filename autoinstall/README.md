### Reference

+ [autoinstall reference](https://canonical-subiquity.readthedocs-hosted.com/en/latest/reference/autoinstall-reference.html)
+ [autoinstall examples](https://docs.cloud-init.io/en/latest/reference/examples.html)
+ [validate autoinstall script](https://canonical-subiquity.readthedocs-hosted.com/en/latest/howto/autoinstall-validation.html)

### Tip & Tricks

+ Error: starting VirtualBox

```bash
VirtualBox can't operate in VMX root mode. Please disable the KVM kernel extension, recompile your kernel and reboot (VERR_VMX_IN_VMX_ROOT_MODE).
````

+ Solution: Disable  KVM kernel extension temporary (reboot to enable again)

```bash
sudo modprobe -r kvm_intel 2>/dev/null
sudo modprobe -r kvm_amd 2>/dev/null
sudo modprobe -r kvm 2>/dev/null
sudo systemctl stop libvirtd 2>/dev/null
sudo systemctl stop virtqemud 2>/dev/null
sudo systemctl stop virtnetworkd 2>/dev/null
```
