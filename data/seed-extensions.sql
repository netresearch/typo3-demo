-- Netresearch Extensions Demo Pages
-- Imported on first boot to showcase Netresearch TYPO3 extensions

-- Parent page: "Extensions" in main navigation
INSERT IGNORE INTO pages (uid, pid, tstamp, crdate, title, slug, doktype, is_siteroot, backend_layout, sorting, hidden, deleted)
VALUES (101, 1, UNIX_TIMESTAMP(), UNIX_TIMESTAMP(), 'Extensions', '/extensions', 1, 0, '', 525, 0, 0);

-- =============================================================================
-- RTE CKEditor Image
-- =============================================================================
INSERT IGNORE INTO pages (uid, pid, tstamp, crdate, title, slug, doktype, sorting, hidden, deleted)
VALUES (102, 101, UNIX_TIMESTAMP(), UNIX_TIMESTAMP(), 'RTE CKEditor Image', '/extensions/rte-ckeditor-image', 1, 100, 0, 0);

INSERT IGNORE INTO tt_content (uid, pid, tstamp, crdate, CType, header, bodytext, colPos, sorting, hidden, deleted)
VALUES (400, 102, UNIX_TIMESTAMP(), UNIX_TIMESTAMP(), 'text', 'RTE CKEditor Image',
'<div class="rounded-3 p-4 mb-4" style="background: linear-gradient(135deg, rgba(47,153,164,0.06), rgba(47,153,164,0.02));">
  <div class="d-flex align-items-center gap-2 mb-2">
    <span class="badge rounded-pill text-white" style="background: #2F99A4; font-size: 0.7rem;">CKEditor</span>
    <span class="badge rounded-pill border" style="font-size: 0.68rem; color: #585961;">TYPO3 v14</span>
    <span class="badge rounded-pill border" style="font-size: 0.68rem; color: #585961;">Open Source</span>
  </div>
  <h2 class="fw-bold mb-2" style="font-size: 1.6rem;">Advanced Image Handling for CKEditor 5</h2>
  <p class="text-muted mb-3" style="font-size: 1rem; max-width: 650px;">Block images, inline images, click-to-enlarge, and linked images — all directly in the TYPO3 rich text editor. No content elements needed.</p>
  <div class="d-flex gap-2 flex-wrap">
    <a href="https://github.com/netresearch/t3x-rte_ckeditor_image" target="_blank" rel="noopener" class="btn btn-sm text-white" style="background: #2F99A4;">GitHub</a>
    <a href="https://extensions.typo3.org/extension/rte_ckeditor_image" target="_blank" rel="noopener" class="btn btn-sm btn-outline-secondary">TER</a>
    <a href="https://packagist.org/packages/netresearch/rte-ckeditor-image" target="_blank" rel="noopener" class="btn btn-sm btn-outline-secondary">Packagist</a>
  </div>
</div>

<div class="row g-3 mb-4">
  <div class="col-md-4">
    <div class="card h-100 border-0" style="background: #f8f9fa;">
      <div class="card-body text-center py-4">
        <h6 class="fw-bold" style="font-size: 0.88rem;">Block Images</h6>
        <p class="text-muted mb-0" style="font-size: 0.78rem;">Standalone images with captions and alignment. Processed as TYPO3 images with responsive srcset.</p>
      </div>
    </div>
  </div>
  <div class="col-md-4">
    <div class="card h-100 border-0" style="background: #f8f9fa;">
      <div class="card-body text-center py-4">
        <h6 class="fw-bold" style="font-size: 0.88rem;">Inline Images</h6>
        <p class="text-muted mb-0" style="font-size: 0.78rem;">Images that flow naturally within text — icons, logos, and small illustrations inline with content.</p>
      </div>
    </div>
  </div>
  <div class="col-md-4">
    <div class="card h-100 border-0" style="background: #f8f9fa;">
      <div class="card-body text-center py-4">
        <h6 class="fw-bold" style="font-size: 0.88rem;">Click-to-Enlarge</h6>
        <p class="text-muted mb-0" style="font-size: 0.78rem;">Lightbox popup via <code>data-htmlarea-zoom</code>. Click any image to view full resolution.</p>
      </div>
    </div>
  </div>
</div>

<h2 class="fw-bold mb-3" style="font-size: 1.2rem;">Live Demos</h2>

<h3 class="fw-bold mb-2" style="font-size: 1rem;">Block Image</h3>
<p class="text-muted mb-2" style="font-size: 0.88rem;">A standalone image inserted via CKEditor — rendered with responsive srcset:</p>
<p><img src="/fileadmin/user_upload/images/Home/CH5_7354.jpg" alt="Team photo demo" width="800" data-htmlarea-file-uid="190" data-htmlarea-file-table="sys_file"></p>

<h3 class="fw-bold mb-2 mt-4" style="font-size: 1rem;">Click-to-Enlarge (Lightbox)</h3>
<p class="text-muted mb-2" style="font-size: 0.88rem;">Click the image below to see the lightbox popup:</p>
<p><img src="/fileadmin/user_upload/images/Home/CH5_7203.jpg" alt="Click to enlarge" width="400" data-htmlarea-file-uid="188" data-htmlarea-file-table="sys_file" data-htmlarea-zoom="true"></p>

<h3 class="fw-bold mb-2 mt-4" style="font-size: 1rem;">Inline Image in Text</h3>
<p style="font-size: 0.88rem;">Text can contain inline images like this <img class="image image-inline" src="/fileadmin/user_upload/images/netresearch-typo3-demo.png" alt="inline logo" width="60" data-htmlarea-file-uid="1" data-htmlarea-file-table="sys_file"> logo that flows naturally within the paragraph.</p>

<div class="alert alert-light border mt-4" role="alert" style="font-size: 0.82rem;">
  <strong style="color: #2F99A4;">For integrators:</strong> Edit this page in the TYPO3 backend to see the CKEditor image toolbar button in action. All images above are inserted via CKEditor, not the standard image content element.
</div>',
0, 100, 0, 0);

-- =============================================================================
-- AI Cowriter
-- =============================================================================
INSERT IGNORE INTO pages (uid, pid, tstamp, crdate, title, slug, doktype, sorting, hidden, deleted)
VALUES (103, 101, UNIX_TIMESTAMP(), UNIX_TIMESTAMP(), 'AI Cowriter', '/extensions/cowriter', 1, 200, 0, 0);

INSERT IGNORE INTO tt_content (uid, pid, tstamp, crdate, CType, header, bodytext, colPos, sorting, hidden, deleted)
VALUES (401, 103, UNIX_TIMESTAMP(), UNIX_TIMESTAMP(), 'text', 'AI Cowriter',
'<div class="rounded-3 p-4 mb-4" style="background: linear-gradient(135deg, rgba(47,153,164,0.06), rgba(47,153,164,0.02));">
  <div class="d-flex align-items-center gap-2 mb-2">
    <span class="badge rounded-pill text-white" style="background: #2F99A4; font-size: 0.7rem;">AI</span>
    <span class="badge rounded-pill border" style="font-size: 0.68rem; color: #585961;">CKEditor Plugin</span>
    <span class="badge rounded-pill border" style="font-size: 0.68rem; color: #585961;">TYPO3 v14</span>
  </div>
  <h2 class="fw-bold mb-2" style="font-size: 1.6rem;">AI-Powered Content Assistant</h2>
  <p class="text-muted mb-3" style="font-size: 1rem; max-width: 650px;">Select text in CKEditor and let AI rewrite, summarize, translate, or fix grammar. Configurable tasks with custom prompts.</p>
  <div class="d-flex gap-2 flex-wrap">
    <a href="https://github.com/netresearch/t3x-cowriter" target="_blank" rel="noopener" class="btn btn-sm text-white" style="background: #2F99A4;">GitHub</a>
    <a href="https://packagist.org/packages/netresearch/t3-cowriter" target="_blank" rel="noopener" class="btn btn-sm btn-outline-secondary">Packagist</a>
  </div>
</div>

<div class="row g-3 mb-4">
  <div class="col-md-4">
    <div class="card h-100 border-0" style="background: #f8f9fa;">
      <div class="card-body">
        <h6 class="fw-bold" style="font-size: 0.9rem; color: #2F99A4;">Rewrite &amp; Rephrase</h6>
        <p class="text-muted mb-0" style="font-size: 0.82rem;">Change tone from formal to casual, simplify complex text, or rephrase for clarity — all without leaving the editor.</p>
      </div>
    </div>
  </div>
  <div class="col-md-4">
    <div class="card h-100 border-0" style="background: #f8f9fa;">
      <div class="card-body">
        <h6 class="fw-bold" style="font-size: 0.9rem; color: #2F99A4;">Summarize &amp; Extend</h6>
        <p class="text-muted mb-0" style="font-size: 0.82rem;">Condense long articles into key points, or expand bullet points into full paragraphs with context.</p>
      </div>
    </div>
  </div>
  <div class="col-md-4">
    <div class="card h-100 border-0" style="background: #f8f9fa;">
      <div class="card-body">
        <h6 class="fw-bold" style="font-size: 0.9rem; color: #2F99A4;">Translate &amp; Fix</h6>
        <p class="text-muted mb-0" style="font-size: 0.82rem;">Translate between languages or fix grammar and spelling mistakes. Custom tasks with configurable prompts.</p>
      </div>
    </div>
  </div>
</div>

<div class="rounded-3 p-3 mb-4" style="background: #f8f9fa;">
  <h5 class="fw-bold mb-3" style="font-size: 0.95rem;">How it works</h5>
  <div class="d-flex flex-column gap-2">
    <div class="d-flex align-items-start gap-2">
      <span class="badge rounded-circle text-white flex-shrink-0 d-flex align-items-center justify-content-center" style="width: 24px; height: 24px; font-size: 0.7rem; background: #2F99A4;">1</span>
      <span style="font-size: 0.84rem;">Configure an LLM provider in the <a href="/extensions/nr-llm/" style="color: #2F99A4;">NR LLM</a> backend module</span>
    </div>
    <div class="d-flex align-items-start gap-2">
      <span class="badge rounded-circle text-white flex-shrink-0 d-flex align-items-center justify-content-center" style="width: 24px; height: 24px; font-size: 0.7rem; background: #2F99A4;">2</span>
      <span style="font-size: 0.84rem;">Select text in CKEditor and click the Cowriter toolbar button</span>
    </div>
    <div class="d-flex align-items-start gap-2">
      <span class="badge rounded-circle text-white flex-shrink-0 d-flex align-items-center justify-content-center" style="width: 24px; height: 24px; font-size: 0.7rem; background: #2F99A4;">3</span>
      <span style="font-size: 0.84rem;">Choose a task (Rewrite, Summarize, Translate, etc.) or write a custom prompt</span>
    </div>
    <div class="d-flex align-items-start gap-2">
      <span class="badge rounded-circle text-white flex-shrink-0 d-flex align-items-center justify-content-center" style="width: 24px; height: 24px; font-size: 0.7rem; background: #FF4D00;">4</span>
      <span style="font-size: 0.84rem;">Review the AI suggestion and apply it with one click</span>
    </div>
  </div>
</div>

<div class="alert alert-light border" role="alert" style="font-size: 0.82rem;">
  <strong style="color: #2F99A4;">Try it:</strong> Edit this page in the TYPO3 backend to see the Cowriter button in the CKEditor toolbar.
</div>',
0, 100, 0, 0);

-- =============================================================================
-- NR LLM
-- =============================================================================
INSERT IGNORE INTO pages (uid, pid, tstamp, crdate, title, slug, doktype, sorting, hidden, deleted)
VALUES (104, 101, UNIX_TIMESTAMP(), UNIX_TIMESTAMP(), 'LLM Foundation', '/extensions/nr-llm', 1, 300, 0, 0);

INSERT IGNORE INTO tt_content (uid, pid, tstamp, crdate, CType, header, bodytext, colPos, sorting, hidden, deleted)
VALUES (402, 104, UNIX_TIMESTAMP(), UNIX_TIMESTAMP(), 'text', 'NR LLM — AI Foundation for TYPO3',
'<div class="rounded-3 p-4 mb-4" style="background: linear-gradient(135deg, rgba(88,89,97,0.06), rgba(88,89,97,0.02));">
  <div class="d-flex align-items-center gap-2 mb-2">
    <span class="badge rounded-pill text-white" style="background: #585961; font-size: 0.7rem;">Core</span>
    <span class="badge rounded-pill border" style="font-size: 0.68rem; color: #585961;">Foundation</span>
    <span class="badge rounded-pill border" style="font-size: 0.68rem; color: #585961;">TYPO3 v14</span>
  </div>
  <h2 class="fw-bold mb-2" style="font-size: 1.6rem;">One LLM Setup for Every Extension</h2>
  <p class="text-muted mb-3" style="font-size: 1rem; max-width: 650px;">The shared AI foundation for TYPO3. Configure providers, models, and task templates once — every AI extension on your site uses them.</p>
  <div class="d-flex gap-2 flex-wrap">
    <a href="https://github.com/netresearch/t3x-nr-llm" target="_blank" rel="noopener" class="btn btn-sm text-white" style="background: #585961;">GitHub</a>
    <a href="https://packagist.org/packages/netresearch/nr-llm" target="_blank" rel="noopener" class="btn btn-sm btn-outline-secondary">Packagist</a>
  </div>
</div>

<div class="row g-3 mb-4">
  <div class="col-md-6">
    <div class="card h-100 border-0" style="background: #f8f9fa;">
      <div class="card-body">
        <h6 class="fw-bold" style="font-size: 0.9rem; color: #585961;">Provider Management</h6>
        <p class="text-muted mb-0" style="font-size: 0.82rem;">Configure Ollama, OpenAI, Anthropic, Google, or custom API endpoints. Switch providers without touching extension code.</p>
      </div>
    </div>
  </div>
  <div class="col-md-6">
    <div class="card h-100 border-0" style="background: #f8f9fa;">
      <div class="card-body">
        <h6 class="fw-bold" style="font-size: 0.9rem; color: #585961;">Model Registry</h6>
        <p class="text-muted mb-0" style="font-size: 0.82rem;">Manage available models with temperature, token limits, and context window settings. Assign models to specific tasks.</p>
      </div>
    </div>
  </div>
  <div class="col-md-6">
    <div class="card h-100 border-0" style="background: #f8f9fa;">
      <div class="card-body">
        <h6 class="fw-bold" style="font-size: 0.9rem; color: #585961;">Task Templates</h6>
        <p class="text-muted mb-0" style="font-size: 0.82rem;">Reusable prompt templates shared across extensions. Define system prompts, output formats, and constraints once.</p>
      </div>
    </div>
  </div>
  <div class="col-md-6">
    <div class="card h-100 border-0" style="background: #f8f9fa;">
      <div class="card-body">
        <h6 class="fw-bold" style="font-size: 0.9rem; color: #585961;">Backend Module</h6>
        <p class="text-muted mb-0" style="font-size: 0.82rem;">Visual management of all LLM resources under Admin Tools &gt; LLM. Test prompts, monitor usage, configure profiles.</p>
      </div>
    </div>
  </div>
</div>

<div class="alert alert-light border" role="alert" style="font-size: 0.82rem;">
  <strong style="color: #585961;">Powers:</strong> <a href="/extensions/cowriter/" style="color: #2F99A4;">AI Cowriter</a> and <a href="/extensions/landing-page/" style="color: #2F99A4;">Landing Page Generator</a> both use NR LLM for their AI capabilities.
</div>',
0, 100, 0, 0);

-- =============================================================================
-- Landing Page Generator
-- =============================================================================
INSERT IGNORE INTO pages (uid, pid, tstamp, crdate, title, slug, doktype, sorting, hidden, deleted)
VALUES (105, 101, UNIX_TIMESTAMP(), UNIX_TIMESTAMP(), 'Landing Page Generator', '/extensions/landing-page', 1, 400, 0, 0);

INSERT IGNORE INTO tt_content (uid, pid, tstamp, crdate, CType, header, bodytext, colPos, sorting, hidden, deleted)
VALUES (403, 105, UNIX_TIMESTAMP(), UNIX_TIMESTAMP(), 'text', 'AI Landing Page Generator',
'<div class="rounded-3 p-4 mb-4" style="background: linear-gradient(135deg, rgba(47,153,164,0.06), rgba(47,153,164,0.02));">
  <div class="d-flex align-items-center gap-2 mb-2">
    <span class="badge rounded-pill text-white" style="background: #2F99A4; font-size: 0.7rem;">AI</span>
    <span class="badge rounded-pill border" style="font-size: 0.68rem; color: #585961;">Backend Wizard</span>
    <span class="badge rounded-pill border" style="font-size: 0.68rem; color: #585961;">TYPO3 v14</span>
  </div>
  <h2 class="fw-bold mb-2" style="font-size: 1.6rem;">Generate Landing Pages with AI</h2>
  <p class="text-muted mb-3" style="font-size: 1rem; max-width: 650px;">Describe your goal and let AI create a complete, structured TYPO3 page with hero, features, content sections, and call-to-action.</p>
  <div class="d-flex gap-2 flex-wrap">
    <a href="https://github.com/netresearch/nr-landingpage" target="_blank" rel="noopener" class="btn btn-sm text-white" style="background: #2F99A4;">GitHub</a>
    <a href="https://packagist.org/packages/netresearch/nr-landingpage" target="_blank" rel="noopener" class="btn btn-sm btn-outline-secondary">Packagist</a>
  </div>
</div>

<div class="row g-3 mb-4">
  <div class="col-md-6">
    <div class="card h-100 border-0" style="background: #f8f9fa;">
      <div class="card-body">
        <h6 class="fw-bold" style="font-size: 0.9rem; color: #2F99A4;">Structured Output</h6>
        <p class="text-muted mb-0" style="font-size: 0.82rem;">AI generates real TYPO3 content elements — hero sections, feature grids, text blocks, and contact forms. Not just text blobs.</p>
      </div>
    </div>
  </div>
  <div class="col-md-6">
    <div class="card h-100 border-0" style="background: #f8f9fa;">
      <div class="card-body">
        <h6 class="fw-bold" style="font-size: 0.9rem; color: #2F99A4;">Backend Wizard</h6>
        <p class="text-muted mb-0" style="font-size: 0.82rem;">Visual wizard under Web &gt; Landing Pages. Enter your brief, choose a template, review the result, and publish.</p>
      </div>
    </div>
  </div>
</div>

<div class="alert alert-light border" role="alert" style="font-size: 0.82rem;">
  <strong style="color: #2F99A4;">Requires:</strong> <a href="/extensions/nr-llm/" style="color: #2F99A4;">NR LLM</a> with a configured provider. Access the wizard in the TYPO3 backend under Web &gt; Landing Pages.
</div>',
0, 100, 0, 0);

-- =============================================================================
-- Passkeys Backend
-- =============================================================================
INSERT IGNORE INTO pages (uid, pid, tstamp, crdate, title, slug, doktype, sorting, hidden, deleted)
VALUES (106, 101, UNIX_TIMESTAMP(), UNIX_TIMESTAMP(), 'Passkeys (Backend)', '/extensions/passkeys-be', 1, 500, 0, 0);

INSERT IGNORE INTO tt_content (uid, pid, tstamp, crdate, CType, header, bodytext, colPos, sorting, hidden, deleted)
VALUES (404, 106, UNIX_TIMESTAMP(), UNIX_TIMESTAMP(), 'text', 'Passwordless Backend Login with Passkeys',
'<div class="rounded-3 p-4 mb-4" style="background: linear-gradient(135deg, rgba(255,77,0,0.04), rgba(255,77,0,0.01));">
  <div class="d-flex align-items-center gap-2 mb-2">
    <span class="badge rounded-pill text-white" style="background: #FF4D00; font-size: 0.7rem;">Security</span>
    <span class="badge rounded-pill border" style="font-size: 0.68rem; color: #585961;">WebAuthn</span>
    <span class="badge rounded-pill border" style="font-size: 0.68rem; color: #585961;">TYPO3 v14</span>
  </div>
  <h2 class="fw-bold mb-2" style="font-size: 1.6rem;">Passwordless Backend Login</h2>
  <p class="text-muted mb-3" style="font-size: 1rem; max-width: 650px;">WebAuthn/FIDO2 passkey authentication for TYPO3 backend users. Replace passwords with fingerprint, face recognition, or security keys.</p>
  <div class="d-flex gap-2 flex-wrap">
    <a href="https://github.com/netresearch/t3x-nr-passkeys-be" target="_blank" rel="noopener" class="btn btn-sm text-white" style="background: #FF4D00;">GitHub</a>
    <a href="https://packagist.org/packages/netresearch/nr-passkeys-be" target="_blank" rel="noopener" class="btn btn-sm btn-outline-secondary">Packagist</a>
  </div>
</div>

<div class="row g-3 mb-4">
  <div class="col-md-6">
    <div class="card h-100 border-0" style="background: #f8f9fa;">
      <div class="card-body">
        <h6 class="fw-bold" style="font-size: 0.9rem;">Per-Group Enforcement</h6>
        <p class="text-muted mb-0" style="font-size: 0.82rem;">Four levels: <strong>Off</strong>, <strong>Encourage</strong> (nudge on login), <strong>Required</strong> (grace period), <strong>Enforced</strong> (immediate). Configure per backend user group.</p>
      </div>
    </div>
  </div>
  <div class="col-md-6">
    <div class="card h-100 border-0" style="background: #f8f9fa;">
      <div class="card-body">
        <h6 class="fw-bold" style="font-size: 0.9rem;">Adoption Dashboard</h6>
        <p class="text-muted mb-0" style="font-size: 0.82rem;">Track passkey rollout across all backend users. See who has registered, who needs nudging, and overall adoption rates.</p>
      </div>
    </div>
  </div>
  <div class="col-md-6">
    <div class="card h-100 border-0" style="background: #f8f9fa;">
      <div class="card-body">
        <h6 class="fw-bold" style="font-size: 0.9rem;">Multi-Device Support</h6>
        <p class="text-muted mb-0" style="font-size: 0.82rem;">Register passkeys on laptop, phone, and security keys. Manage all credentials under User Settings &gt; Passkeys.</p>
      </div>
    </div>
  </div>
  <div class="col-md-6">
    <div class="card h-100 border-0" style="background: #f8f9fa;">
      <div class="card-body">
        <h6 class="fw-bold" style="font-size: 0.9rem;">Interstitial Prompts</h6>
        <p class="text-muted mb-0" style="font-size: 0.82rem;">Configurable enrollment prompts after password login. Encourage adoption gradually or enforce immediately.</p>
      </div>
    </div>
  </div>
</div>

<p class="text-muted" style="font-size: 0.82rem;">See also: <a href="/extensions/passkeys-fe/" style="color: #2F99A4; font-weight: 600;">Passkeys (Frontend)</a> for frontend user authentication.</p>',
0, 100, 0, 0);

-- =============================================================================
-- Passkeys Frontend
-- =============================================================================
INSERT IGNORE INTO pages (uid, pid, tstamp, crdate, title, slug, doktype, sorting, hidden, deleted)
VALUES (109, 101, UNIX_TIMESTAMP(), UNIX_TIMESTAMP(), 'Passkeys (Frontend)', '/extensions/passkeys-fe', 1, 510, 0, 0);

INSERT IGNORE INTO tt_content (uid, pid, tstamp, crdate, CType, header, bodytext, colPos, sorting, hidden, deleted)
VALUES (407, 109, UNIX_TIMESTAMP(), UNIX_TIMESTAMP(), 'text', 'Passkey-First Frontend Authentication',
'<div class="rounded-3 p-4 mb-4" style="background: linear-gradient(135deg, rgba(255,77,0,0.04), rgba(255,77,0,0.01));">
  <div class="d-flex align-items-center gap-2 mb-2">
    <span class="badge rounded-pill text-white" style="background: #FF4D00; font-size: 0.7rem;">Security</span>
    <span class="badge rounded-pill border" style="font-size: 0.68rem; color: #585961;">WebAuthn</span>
    <span class="badge rounded-pill border" style="font-size: 0.68rem; color: #585961;">TYPO3 v14</span>
  </div>
  <h2 class="fw-bold mb-2" style="font-size: 1.6rem;">Passkey-First Frontend Authentication</h2>
  <p class="text-muted mb-3" style="font-size: 1rem; max-width: 650px;">WebAuthn/FIDO2 passkey login for TYPO3 frontend users. Replace passwords with biometrics — fingerprint, face recognition, or security keys.</p>
  <div class="d-flex gap-2 flex-wrap">
    <a href="/login" class="btn btn-sm text-white" style="background: #FF4D00;">Try Live Demo</a>
    <a href="https://github.com/netresearch/t3x-nr-passkeys-fe" target="_blank" rel="noopener" class="btn btn-sm text-white" style="background: #2F99A4;">GitHub</a>
    <a href="https://packagist.org/packages/netresearch/nr-passkeys-fe" target="_blank" rel="noopener" class="btn btn-sm btn-outline-secondary">Packagist</a>
  </div>
</div>

<div class="row g-3 mb-4">
  <div class="col-md-6">
    <div class="card h-100 border-0" style="background: #f8f9fa;">
      <div class="card-body">
        <h6 class="fw-bold" style="font-size: 0.9rem;">Passkey-First Login</h6>
        <p class="text-muted mb-0" style="font-size: 0.82rem;">Tabbed felogin override: Passkey tab is default, password tab as fallback. Discoverable credentials via browser autofill.</p>
      </div>
    </div>
  </div>
  <div class="col-md-6">
    <div class="card h-100 border-0" style="background: #f8f9fa;">
      <div class="card-body">
        <h6 class="fw-bold" style="font-size: 0.9rem;">Management Plugin</h6>
        <p class="text-muted mb-0" style="font-size: 0.82rem;">Frontend plugin for users to register, rename, and remove passkeys. Recovery codes for account access if all keys are lost.</p>
      </div>
    </div>
  </div>
  <div class="col-md-6">
    <div class="card h-100 border-0" style="background: #f8f9fa;">
      <div class="card-body">
        <h6 class="fw-bold" style="font-size: 0.9rem;">Zero Template Work</h6>
        <p class="text-muted mb-0" style="font-size: 0.82rem;">Drop-in felogin override. Passkey tab, management UI, and enrollment prompts work out of the box. No Fluid templates to write.</p>
      </div>
    </div>
  </div>
  <div class="col-md-6">
    <div class="card h-100 border-0" style="background: #f8f9fa;">
      <div class="card-body">
        <h6 class="fw-bold" style="font-size: 0.9rem;">Recovery Codes</h6>
        <p class="text-muted mb-0" style="font-size: 0.82rem;">One-time recovery codes for account access if all passkeys are lost. Generate, download, and manage via frontend UI.</p>
      </div>
    </div>
  </div>
</div>

<div class="rounded-3 p-3 mb-4" style="background: #f8f9fa;">
  <h5 class="fw-bold mb-3" style="font-size: 0.95rem;">How it works</h5>
  <div class="d-flex flex-column gap-2">
    <div class="d-flex align-items-start gap-2">
      <span class="badge rounded-circle text-white flex-shrink-0 d-flex align-items-center justify-content-center" style="width: 24px; height: 24px; font-size: 0.7rem; background: #2F99A4;">1</span>
      <span style="font-size: 0.84rem;"><code>composer require netresearch/nr-passkeys-fe</code></span>
    </div>
    <div class="d-flex align-items-start gap-2">
      <span class="badge rounded-circle text-white flex-shrink-0 d-flex align-items-center justify-content-center" style="width: 24px; height: 24px; font-size: 0.7rem; background: #2F99A4;">2</span>
      <span style="font-size: 0.84rem;">Add the passkey management plugin to a protected page</span>
    </div>
    <div class="d-flex align-items-start gap-2">
      <span class="badge rounded-circle text-white flex-shrink-0 d-flex align-items-center justify-content-center" style="width: 24px; height: 24px; font-size: 0.7rem; background: #2F99A4;">3</span>
      <span style="font-size: 0.84rem;">Felogin gets a passkey tab automatically — users see biometric login first</span>
    </div>
    <div class="d-flex align-items-start gap-2">
      <span class="badge rounded-circle text-white flex-shrink-0 d-flex align-items-center justify-content-center" style="width: 24px; height: 24px; font-size: 0.7rem; background: #FF4D00;">4</span>
      <span style="font-size: 0.84rem;">Users register passkeys and log in with fingerprint, face, or security key</span>
    </div>
  </div>
</div>

<p class="text-muted" style="font-size: 0.82rem;">See also: <a href="/extensions/passkeys-be/" style="color: #2F99A4; font-weight: 600;">Passkeys (Backend)</a> for backend user authentication.</p>',
0, 100, 0, 0);

-- =============================================================================
-- Secrets Vault
-- =============================================================================
INSERT IGNORE INTO pages (uid, pid, tstamp, crdate, title, slug, doktype, sorting, hidden, deleted)
VALUES (107, 101, UNIX_TIMESTAMP(), UNIX_TIMESTAMP(), 'Secrets Vault', '/extensions/vault', 1, 600, 0, 0);

INSERT IGNORE INTO tt_content (uid, pid, tstamp, crdate, CType, header, bodytext, colPos, sorting, hidden, deleted)
VALUES (405, 107, UNIX_TIMESTAMP(), UNIX_TIMESTAMP(), 'text', 'NR Vault — Secure Secrets Management',
'<div class="rounded-3 p-4 mb-4" style="background: linear-gradient(135deg, rgba(255,77,0,0.04), rgba(255,77,0,0.01));">
  <div class="d-flex align-items-center gap-2 mb-2">
    <span class="badge rounded-pill text-white" style="background: #FF4D00; font-size: 0.7rem;">Security</span>
    <span class="badge rounded-pill border" style="font-size: 0.68rem; color: #585961;">Enterprise</span>
    <span class="badge rounded-pill border" style="font-size: 0.68rem; color: #585961;">TYPO3 v14</span>
  </div>
  <h2 class="fw-bold mb-2" style="font-size: 1.6rem;">Enterprise Secrets Management</h2>
  <p class="text-muted mb-3" style="font-size: 1rem; max-width: 650px;">Envelope encryption, access control, audit logging, and key rotation for TYPO3. Stop storing API keys in plain text.</p>
  <div class="d-flex gap-2 flex-wrap">
    <a href="https://github.com/netresearch/t3x-nr-vault" target="_blank" rel="noopener" class="btn btn-sm text-white" style="background: #FF4D00;">GitHub</a>
    <a href="https://packagist.org/packages/netresearch/nr-vault" target="_blank" rel="noopener" class="btn btn-sm btn-outline-secondary">Packagist</a>
  </div>
</div>

<div class="row g-3 mb-4">
  <div class="col-md-6">
    <div class="card h-100 border-0" style="background: #f8f9fa;">
      <div class="card-body">
        <h6 class="fw-bold" style="font-size: 0.9rem;">Envelope Encryption</h6>
        <p class="text-muted mb-0" style="font-size: 0.82rem;">Each secret encrypted with its own data key, wrapped by a master key. Industry-standard envelope encryption pattern.</p>
      </div>
    </div>
  </div>
  <div class="col-md-6">
    <div class="card h-100 border-0" style="background: #f8f9fa;">
      <div class="card-body">
        <h6 class="fw-bold" style="font-size: 0.9rem;">Access Control</h6>
        <p class="text-muted mb-0" style="font-size: 0.82rem;">Scope secrets to extensions, backend user groups, or environments. Granular permissions for who can read what.</p>
      </div>
    </div>
  </div>
  <div class="col-md-6">
    <div class="card h-100 border-0" style="background: #f8f9fa;">
      <div class="card-body">
        <h6 class="fw-bold" style="font-size: 0.9rem;">CLI &amp; Backend Module</h6>
        <p class="text-muted mb-0" style="font-size: 0.82rem;"><code>vault:init</code>, <code>vault:store</code>, <code>vault:retrieve</code>, <code>vault:rotate</code> — manage secrets via CLI or the visual backend module.</p>
      </div>
    </div>
  </div>
  <div class="col-md-6">
    <div class="card h-100 border-0" style="background: #f8f9fa;">
      <div class="card-body">
        <h6 class="fw-bold" style="font-size: 0.9rem;">Audit &amp; Rotation</h6>
        <p class="text-muted mb-0" style="font-size: 0.82rem;">Full audit trail of who accessed which secret and when. Rotate master keys without re-encrypting all secrets.</p>
      </div>
    </div>
  </div>
</div>',
0, 100, 0, 0);

-- =============================================================================
-- Temporal Cache
-- =============================================================================
INSERT IGNORE INTO pages (uid, pid, tstamp, crdate, title, slug, doktype, sorting, hidden, deleted)
VALUES (108, 101, UNIX_TIMESTAMP(), UNIX_TIMESTAMP(), 'Temporal Cache', '/extensions/temporal-cache', 1, 700, 0, 0);

INSERT IGNORE INTO tt_content (uid, pid, tstamp, crdate, CType, header, bodytext, colPos, sorting, hidden, deleted)
VALUES (406, 108, UNIX_TIMESTAMP(), UNIX_TIMESTAMP(), 'text', 'Automatic Cache Invalidation for Timed Content',
'<div class="rounded-3 p-4 mb-4" style="background: linear-gradient(135deg, rgba(88,89,97,0.06), rgba(88,89,97,0.02));">
  <div class="d-flex align-items-center gap-2 mb-2">
    <span class="badge rounded-pill text-white" style="background: #585961; font-size: 0.7rem;">Cache</span>
    <span class="badge rounded-pill border" style="font-size: 0.68rem; color: #585961;">Performance</span>
    <span class="badge rounded-pill border" style="font-size: 0.68rem; color: #585961;">TYPO3 v14</span>
  </div>
  <h2 class="fw-bold mb-2" style="font-size: 1.6rem;">Timed Content, Automatic Cache</h2>
  <p class="text-muted mb-3" style="font-size: 1rem; max-width: 650px;">Solves <a href="https://forge.typo3.org/issues/14277" target="_blank" rel="noopener" style="color: #2F99A4;">TYPO3 Forge #14277</a>: content with start/end times stays cached beyond its visibility window. This extension fixes that — automatically.</p>
  <div class="d-flex gap-2 flex-wrap">
    <a href="https://github.com/netresearch/t3x-nr-temporal-cache" target="_blank" rel="noopener" class="btn btn-sm text-white" style="background: #585961;">GitHub</a>
    <a href="https://packagist.org/packages/netresearch/nr-temporal-cache" target="_blank" rel="noopener" class="btn btn-sm btn-outline-secondary">Packagist</a>
  </div>
</div>

<div class="row g-3 mb-4">
  <div class="col-md-6">
    <div class="card h-100 border-0" style="background: #f8f9fa;">
      <div class="card-body">
        <h6 class="fw-bold" style="font-size: 0.9rem;">Automatic Invalidation</h6>
        <p class="text-muted mb-0" style="font-size: 0.82rem;">Cache clears precisely when content becomes visible or expires. No more stale pages showing hidden content.</p>
      </div>
    </div>
  </div>
  <div class="col-md-6">
    <div class="card h-100 border-0" style="background: #f8f9fa;">
      <div class="card-body">
        <h6 class="fw-bold" style="font-size: 0.9rem;">Flexible Scoping</h6>
        <p class="text-muted mb-0" style="font-size: 0.82rem;">Invalidate single pages, page trees, or all pages. Scheduler-based or on-demand cache clearing strategies.</p>
      </div>
    </div>
  </div>
</div>

<div class="alert alert-light border" role="alert" style="font-size: 0.82rem;">
  <strong style="color: #585961;">Zero config:</strong> Works transparently with all content types that use TYPO3 starttime/endtime fields. Install and forget.
</div>',
0, 100, 0, 0);

-- =============================================================================
-- Overview Hub (/extensions)
-- =============================================================================
INSERT IGNORE INTO tt_content (uid, pid, tstamp, crdate, CType, header, bodytext, colPos, sorting, hidden, deleted)
VALUES (410, 101, UNIX_TIMESTAMP(), UNIX_TIMESTAMP(), 'text', 'Netresearch TYPO3 Extensions',
'<div class="text-center mb-4">
  <p class="lead text-muted mx-auto" style="max-width: 600px;">Open-source extensions for TYPO3 v14. Built for editors, integrators, and developers.</p>
</div>

<h5 class="fw-bold text-uppercase mb-3" style="font-size: 0.75rem; letter-spacing: 0.12em; color: #2F99A4;"><span style="display: inline-block; width: 20px; height: 2px; background: #2F99A4; vertical-align: middle; margin-right: 0.5rem;"></span>Content &amp; Editing</h5>
<div class="row g-3 mb-4">
  <div class="col-md-4">
    <div class="card h-100 border-0 shadow-sm"><div class="card-body">
      <div class="d-flex align-items-center gap-2 mb-2">
        <span class="badge rounded-pill text-white" style="background: #2F99A4; font-size: 0.65rem;">CKEditor</span>
        <h6 class="card-title fw-bold mb-0" style="font-size: 0.92rem;">RTE CKEditor Image</h6>
      </div>
      <p class="card-text text-muted" style="font-size: 0.82rem;">Block images, inline images, lightbox, and linked images in the rich text editor.</p>
      <a href="/extensions/rte-ckeditor-image/" class="fw-semibold text-decoration-none" style="font-size: 0.82rem; color: #FF4D00;">Explore &rarr;</a>
    </div></div>
  </div>
  <div class="col-md-4">
    <div class="card h-100 border-0 shadow-sm"><div class="card-body">
      <div class="d-flex align-items-center gap-2 mb-2">
        <span class="badge rounded-pill text-white" style="background: #2F99A4; font-size: 0.65rem;">AI</span>
        <h6 class="card-title fw-bold mb-0" style="font-size: 0.92rem;">AI Cowriter</h6>
      </div>
      <p class="card-text text-muted" style="font-size: 0.82rem;">Rewrite, summarize, translate, and fix grammar — AI assistant in CKEditor.</p>
      <a href="/extensions/cowriter/" class="fw-semibold text-decoration-none" style="font-size: 0.82rem; color: #FF4D00;">Explore &rarr;</a>
    </div></div>
  </div>
  <div class="col-md-4">
    <div class="card h-100 border-0 shadow-sm"><div class="card-body">
      <div class="d-flex align-items-center gap-2 mb-2">
        <span class="badge rounded-pill text-white" style="background: #2F99A4; font-size: 0.65rem;">AI</span>
        <h6 class="card-title fw-bold mb-0" style="font-size: 0.92rem;">Landing Page Generator</h6>
      </div>
      <p class="card-text text-muted" style="font-size: 0.82rem;">Create complete landing pages with hero, features, and CTAs using AI.</p>
      <a href="/extensions/landing-page/" class="fw-semibold text-decoration-none" style="font-size: 0.82rem; color: #FF4D00;">Explore &rarr;</a>
    </div></div>
  </div>
</div>

<h5 class="fw-bold text-uppercase mb-3" style="font-size: 0.75rem; letter-spacing: 0.12em; color: #2F99A4;"><span style="display: inline-block; width: 20px; height: 2px; background: #2F99A4; vertical-align: middle; margin-right: 0.5rem;"></span>AI Foundation</h5>
<div class="row g-3 mb-4">
  <div class="col-md-6">
    <div class="card h-100 border-0 shadow-sm"><div class="card-body">
      <div class="d-flex align-items-center gap-2 mb-2">
        <span class="badge rounded-pill text-white" style="background: #585961; font-size: 0.65rem;">Core</span>
        <h6 class="card-title fw-bold mb-0" style="font-size: 0.92rem;">NR LLM</h6>
      </div>
      <p class="card-text text-muted" style="font-size: 0.82rem;">One LLM setup for every extension. Providers, models, task templates, and a visual backend module.</p>
      <a href="/extensions/nr-llm/" class="fw-semibold text-decoration-none" style="font-size: 0.82rem; color: #FF4D00;">Explore &rarr;</a>
    </div></div>
  </div>
</div>

<h5 class="fw-bold text-uppercase mb-3" style="font-size: 0.75rem; letter-spacing: 0.12em; color: #FF4D00;"><span style="display: inline-block; width: 20px; height: 2px; background: #FF4D00; vertical-align: middle; margin-right: 0.5rem;"></span>Security &amp; Authentication</h5>
<div class="row g-3 mb-4">
  <div class="col-md-4">
    <div class="card h-100 border-0 shadow-sm"><div class="card-body">
      <div class="d-flex align-items-center gap-2 mb-2">
        <span class="badge rounded-pill text-white" style="background: #FF4D00; font-size: 0.65rem;">Security</span>
        <h6 class="card-title fw-bold mb-0" style="font-size: 0.92rem;">Passkeys (Backend)</h6>
      </div>
      <p class="card-text text-muted" style="font-size: 0.82rem;">Passwordless WebAuthn login for backend users with per-group enforcement.</p>
      <a href="/extensions/passkeys-be/" class="fw-semibold text-decoration-none" style="font-size: 0.82rem; color: #FF4D00;">Explore &rarr;</a>
    </div></div>
  </div>
  <div class="col-md-4">
    <div class="card h-100 border-0 shadow-sm"><div class="card-body">
      <div class="d-flex align-items-center gap-2 mb-2">
        <span class="badge rounded-pill text-white" style="background: #FF4D00; font-size: 0.65rem;">Security</span>
        <h6 class="card-title fw-bold mb-0" style="font-size: 0.92rem;">Passkeys (Frontend)</h6>
      </div>
      <p class="card-text text-muted" style="font-size: 0.82rem;">Passkey-first authentication for frontend users. <a href="/login" style="color: #2F99A4;">Try the demo</a>.</p>
      <a href="/extensions/passkeys-fe/" class="fw-semibold text-decoration-none" style="font-size: 0.82rem; color: #FF4D00;">Explore &rarr;</a>
    </div></div>
  </div>
  <div class="col-md-4">
    <div class="card h-100 border-0 shadow-sm"><div class="card-body">
      <div class="d-flex align-items-center gap-2 mb-2">
        <span class="badge rounded-pill text-white" style="background: #FF4D00; font-size: 0.65rem;">Security</span>
        <h6 class="card-title fw-bold mb-0" style="font-size: 0.92rem;">Secrets Vault</h6>
      </div>
      <p class="card-text text-muted" style="font-size: 0.82rem;">Envelope encryption, access control, key rotation, and audit logging.</p>
      <a href="/extensions/vault/" class="fw-semibold text-decoration-none" style="font-size: 0.82rem; color: #FF4D00;">Explore &rarr;</a>
    </div></div>
  </div>
</div>

<h5 class="fw-bold text-uppercase mb-3" style="font-size: 0.75rem; letter-spacing: 0.12em; color: #2F99A4;"><span style="display: inline-block; width: 20px; height: 2px; background: #2F99A4; vertical-align: middle; margin-right: 0.5rem;"></span>Performance</h5>
<div class="row g-3 mb-4">
  <div class="col-md-6">
    <div class="card h-100 border-0 shadow-sm"><div class="card-body">
      <div class="d-flex align-items-center gap-2 mb-2">
        <span class="badge rounded-pill text-white" style="background: #585961; font-size: 0.65rem;">Cache</span>
        <h6 class="card-title fw-bold mb-0" style="font-size: 0.92rem;">Temporal Cache</h6>
      </div>
      <p class="card-text text-muted" style="font-size: 0.82rem;">Automatic cache invalidation when timed content starts or expires.</p>
      <a href="/extensions/temporal-cache/" class="fw-semibold text-decoration-none" style="font-size: 0.82rem; color: #FF4D00;">Explore &rarr;</a>
    </div></div>
  </div>
</div>

<div class="text-center mt-4 pt-3" style="border-top: 1px solid rgba(0,0,0,0.06);">
  <p class="text-muted mb-2" style="font-size: 0.82rem;">All extensions are open source and TYPO3 v14 compatible.</p>
  <a href="https://github.com/netresearch" target="_blank" rel="noopener" class="btn btn-sm text-white" style="background: #2F99A4;">View all on GitHub</a>
</div>',
0, 100, 0, 0);

-- Demo frontend user for passkey testing (username: demo, password: demo)
INSERT IGNORE INTO fe_users (uid, pid, tstamp, crdate, username, password, usergroup, name, email, disable, deleted)
VALUES (2, 2, UNIX_TIMESTAMP(), UNIX_TIMESTAMP(), 'demo', '$argon2i$v=19$m=65536,t=4,p=1$L2kzRUEvbEdCbk5mWlViNA$2E5UgTQxfndqZIrMAKJHjuJvB9tQphrK/yCGsX7UQao', '1', 'Demo User', 'demo@example.com', 0, 0);

-- Demo credentials hint on login page
INSERT IGNORE INTO tt_content (uid, pid, tstamp, crdate, CType, header, bodytext, colPos, sorting, hidden, deleted)
VALUES (440, 93, UNIX_TIMESTAMP(), UNIX_TIMESTAMP(), 'text', 'Try the Demo Login',
'<div class="alert alert-info">
<p><strong>Demo credentials:</strong></p>
<p>Username: <code>demo</code><br>Password: <code>demo</code></p>
<p>After logging in, you can register a Passkey under your account settings and use it for future logins — try the <strong>Passkey</strong> tab below!</p>
</div>',
0, 100, 0, 0);
