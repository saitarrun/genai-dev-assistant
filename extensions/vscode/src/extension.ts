import * as vscode from 'vscode';
import axios from 'axios';

let statusBar: vscode.StatusBarItem;

export function activate(context: vscode.ExtensionContext) {
    console.log('GenAI Codebase Search extension activated');

    // Create status bar
    statusBar = vscode.window.createStatusBarItem(vscode.StatusBarAlignment.Right, 100);
    statusBar.command = 'genai.search';
    statusBar.text = '$(search) GenAI Search';
    statusBar.tooltip = 'Search your codebase with AI (Ctrl+Shift+G)';
    statusBar.show();

    // Register commands
    let searchCommand = vscode.commands.registerCommand('genai.search', async () => {
        await handleSearch();
    });

    let indexCommand = vscode.commands.registerCommand('genai.indexRepo', async () => {
        await handleIndexing();
    });

    let settingsCommand = vscode.commands.registerCommand('genai.openSettings', async () => {
        vscode.commands.executeCommand('workbench.action.openSettings', 'genai');
    });

    context.subscriptions.push(searchCommand, indexCommand, settingsCommand, statusBar);
}

async function handleSearch() {
    const config = vscode.workspace.getConfiguration('genai');
    const apiUrl = config.get<string>('apiUrl');
    const defaultNamespace = config.get<string>('defaultNamespace');

    if (!apiUrl) {
        vscode.window.showErrorMessage('GenAI: API URL not configured. Run "GenAI: Settings"');
        return;
    }

    // Get user input
    const question = await vscode.window.showInputBox({
        placeHolder: 'Ask a question about your codebase...',
        title: 'GenAI Codebase Search'
    });

    if (!question) {
        return;
    }

    const namespace = await vscode.window.showInputBox({
        placeHolder: 'Repository namespace',
        value: defaultNamespace || ''
    });

    if (!namespace) {
        return;
    }

    // Show progress
    await vscode.window.withProgress(
        {
            location: vscode.ProgressLocation.Notification,
            title: 'Searching...',
            cancellable: false
        },
        async (progress) => {
            try {
                const response = await axios.post(`${apiUrl}/ask`, {
                    question,
                    namespace,
                    top_k: 6
                });

                const { answer, sources } = response.data;

                // Show result in output channel
                const outputChannel = vscode.window.createOutputChannel('GenAI Search');
                outputChannel.clear();
                outputChannel.appendLine(`Question: ${question}\n`);
                outputChannel.appendLine(`Answer:\n${answer}\n`);
                outputChannel.appendLine(`\nSources:`);

                if (sources && sources.length > 0) {
                    sources.forEach((source: any, index: number) => {
                        outputChannel.appendLine(
                            `  ${index + 1}. ${source.file_path} (${(source.score * 100).toFixed(0)}%)`
                        );
                    });
                }

                outputChannel.show();
                vscode.window.showInformationMessage('GenAI: Answer ready in output channel');
            } catch (error: any) {
                vscode.window.showErrorMessage(`GenAI Error: ${error.message}`);
            }
        }
    );
}

async function handleIndexing() {
    const workspaceFolder = vscode.workspace.workspaceFolders?.[0];
    if (!workspaceFolder) {
        vscode.window.showErrorMessage('GenAI: No workspace folder open');
        return;
    }

    const namespace = await vscode.window.showInputBox({
        placeHolder: 'Repository namespace',
        value: workspaceFolder.name
    });

    if (!namespace) {
        return;
    }

    vscode.window.showInformationMessage(
        `GenAI: To index this repository, run:\n` +
        `python3 -m ingestion.pipeline --repo ${workspaceFolder.uri.fsPath} --namespace ${namespace}`
    );
}

export function deactivate() {
    console.log('GenAI extension deactivated');
}
