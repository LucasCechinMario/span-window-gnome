import Gio from 'gi://Gio';
import Meta from 'gi://Meta';
import Shell from 'gi://Shell';
import * as Main from 'resource:///org/gnome/shell/ui/main.js';

export default class SpanWindowExtension {
    enable() {
        log("SPAN WINDOW V2: extensão iniciada");

        this._settings = new Gio.Settings({
            schema_id: 'org.gnome.shell.extensions.span-window',
        });

        this._maximizeAction = 'span-window-maximize';

        Main.wm.addKeybinding(
            this._maximizeAction,
            this._settings,
            Meta.KeyBindingFlags.NONE,
            Shell.ActionMode.NORMAL,
            () => {
                const window = global.display.get_focus_window();

                if (!window)
                    return;

                let level = window.get_maximize_level();

                log(`SPAN WINDOW V2: nível atual = ${level}`);

                if (level < 3)
                    level++;

                log(`SPAN WINDOW V2: novo nível = ${level}`);

                /*
                 * O unmaximize() do Mutter zera maximize_level.
                 * Portanto, primeiro saímos do estado atual e só
                 * depois aplicamos o novo nível.
                 */

                if (level === 1 || level === 2) {
                    if (window.is_fullscreen())
                        window.unmake_fullscreen();

                    if (window.is_maximized())
                        window.unmaximize();

                    window.set_maximize_level(level);
                    window.maximize();

                    log(`SPAN WINDOW V2: nível ${level} aplicado`);
                    return;
                }

                if (level === 3) {
                    /*
                     * Nível 3:
                     * fullscreen real através de todos os monitores.
                     *
                     * O unmaximize() zera maximize_level, portanto
                     * primeiro saímos do estado maximizado e depois
                     * configuramos o nível 3.
                     */

                    if (window.is_fullscreen())
                        window.unmake_fullscreen();

                    if (window.is_maximized())
                        window.unmaximize();

                    window.set_maximize_level(3);
                    window.make_fullscreen();

                    log("SPAN WINDOW V2: nível 3 fullscreen aplicado");
                    return;
                }
            }
        );

        this._unmaximizeAction = 'span-window-unmaximize';

        Main.wm.addKeybinding(
            this._unmaximizeAction,
            this._settings,
            Meta.KeyBindingFlags.NONE,
            Shell.ActionMode.NORMAL,
            () => {
                const window = global.display.get_focus_window();

                if (!window)
                    return;

                let level = window.get_maximize_level();

                log(`SPAN WINDOW V2: nível atual = ${level}`);

                if (level > 0)
                    level--;

                log(`SPAN WINDOW V2: novo nível = ${level}`);

                /*
                 * Primeiro saímos do estado visual atual.
                 *
                 * Fullscreen e maximizado são estados diferentes
                 * no Mutter, então ambos precisam ser tratados.
                 */

                if (window.is_fullscreen())
                    window.unmake_fullscreen();

                if (window.is_maximized())
                    window.unmaximize();

                /*
                 * Só agora aplicamos o novo nível.
                 */
                window.set_maximize_level(level);

                if (level === 0) {
                    log("SPAN WINDOW V2: janela normal");
                    return;
                }

                if (level === 1 || level === 2) {
                    window.maximize();

                    log(`SPAN WINDOW V2: nível ${level} aplicado`);
                    return;
                }
            }
        );

        log("SPAN WINDOW V2: atalhos registrados");
    }

    disable() {
        log("SPAN WINDOW V2: desabilitando");

        if (this._maximizeAction)
            Main.wm.removeKeybinding(this._maximizeAction);

        if (this._unmaximizeAction)
            Main.wm.removeKeybinding(this._unmaximizeAction);

        this._settings = null;

        log("SPAN WINDOW V2: extensão desabilitada");
    }
}
