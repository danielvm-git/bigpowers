import sys
try:
    import pyfiglet
except ImportError:
    import subprocess
    subprocess.run([sys.executable, '-m', 'pip', 'install', 'pyfiglet'])
    import pyfiglet

text = "BIGPOWERS"
fonts = ['ansi_shadow', 'block', 'colossal', 'epic', 'banner3', 'cyberlarge', 'isometric1', 'rectangles', 'alligator', 'alpha']

for f in fonts:
    try:
        print(f"Font: {f}")
        print(pyfiglet.figlet_format(text, font=f))
    except Exception as e:
        print(f"Error with {f}: {e}")
