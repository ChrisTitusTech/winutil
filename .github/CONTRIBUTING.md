## Contributing Code

### Before You Start

- Keep each pull request focused on a single feature or fix.
- Avoid unnecessary formatting changes or large unrelated edits.
- Document what changed and why in your PR description.

---

## Basic Git Workflow

### 1. Fork the Repository

Go to the ChrisTitusTech/winutil repository on GitHub and click the Fork button in the top right corner.

<img width="171" height="50" alt="{650A4723-F38A-44A4-9820-D232BC87C8A0}" src="https://github.com/user-attachments/assets/a214f27c-2fee-444a-920f-d87b14f5896f" />

---

### 2. Clone Your Fork

```powershell
git clone https://github.com/YOUR_USERNAME/winutil.git
cd winutil
```

---

### 3. Create a Branch

Never work directly on `main`.

Create a branch related to your change:

```powershell
git checkout -b feature-name
```

Example:

```powershell
git checkout -b add-firefox-tweak
```

---

### 4. Edit the Code

Open the project in your preferred text editor and make your changes.

Keep changes small and focused.

---

### 5. Test Your Changes

Open Powershell as Administrator.

Go to the project folder:

```powershell
cd path\to\winutil
```

Run:

```powershell
.\Compile.ps1 -Run
```

Verify:

- WinUtil launches correctly
- Your feature works
- Nothing else breaks

If something fails, fix it before committing.

---

### 6. Review Your Changes

Check what changed:

```powershell
git status
```

Review the diff:

```powershell
git diff
```

Make sure you did not accidentally modify unrelated files.

---

### 7. Commit Your Changes

Stage files:

```powershell
git add .
```

Commit them:

```powershell
git commit -m "Add feature description"
```

Example:

```powershell
git commit -m "Add Firefox package tweak"
```

---

### 8. Push Your Branch

```powershell
git push origin branch-name
```

Example:

```powershell
git push origin add-firefox-tweak
```

---

### 9. Open a Pull Request

Go to your fork on GitHub.

GitHub will show a button to create a pull request.
<img width="1009" height="71" alt="{C8C6A3CC-79D4-44FD-A54C-4C5717F12730}" src="https://github.com/user-attachments/assets/0419d193-d4e7-47c0-87cf-b986742201a0" />

Before submitting:

- Explain what changed
- Explain why you changed it
- Make sure unrelated files are not included

Once submitted, maintainers will review your PR.
